import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthDaySummary {
  final int steps;
  final double activeEnergyKcal;
  final double? latestWeightKg;

  const HealthDaySummary({
    required this.steps,
    required this.activeEnergyKcal,
    this.latestWeightKg,
  });
}

class HealthWeightSample {
  final double weightKg;
  final DateTime date;

  const HealthWeightSample({required this.weightKg, required this.date});
}

/// Apple Health / Health Connect bridge for MyDiet.
class HealthService {
  HealthService({Health? health}) : _health = health ?? Health();

  static const _prefConnected = 'apple_health_connected';

  final Health _health;
  bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.DIETARY_PROTEIN_CONSUMED,
    HealthDataType.DIETARY_CARBS_CONSUMED,
    HealthDataType.DIETARY_FATS_CONSUMED,
    HealthDataType.DIETARY_FIBER,
    HealthDataType.WATER,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WORKOUT,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ_WRITE, // WEIGHT
    HealthDataAccess.READ_WRITE, // HEIGHT
    HealthDataAccess.READ, // STEPS
    HealthDataAccess.READ, // ACTIVE_ENERGY
    HealthDataAccess.READ, // BASAL_ENERGY
    HealthDataAccess.READ_WRITE, // DIETARY_ENERGY
    HealthDataAccess.READ_WRITE, // PROTEIN
    HealthDataAccess.READ_WRITE, // CARBS
    HealthDataAccess.READ_WRITE, // FATS
    HealthDataAccess.READ_WRITE, // FIBER
    HealthDataAccess.READ_WRITE, // WATER
    HealthDataAccess.READ, // HEART_RATE
    HealthDataAccess.READ, // RESTING_HR
    HealthDataAccess.READ, // SLEEP
    HealthDataAccess.READ, // WORKOUT
  ];

  bool get isSupportedPlatform => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<bool> isConnected() async {
    if (!isSupportedPlatform) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefConnected) ?? false;
  }

  Future<void> _setConnected(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefConnected, value);
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Request HealthKit / Health Connect permissions and mark connected.
  Future<bool> connect() async {
    if (!isSupportedPlatform) return false;
    await _ensureConfigured();
    final ok = await _health.requestAuthorization(
      _types,
      permissions: _permissions,
    );
    if (ok) {
      await _setConnected(true);
    }
    return ok;
  }

  Future<void> disconnect() async {
    await _setConnected(false);
  }

  Future<bool> writeWeightKg(double kg, {DateTime? at}) async {
    if (!await isConnected()) return false;
    await _ensureConfigured();
    final when = at ?? DateTime.now();
    try {
      return await _health.writeHealthData(
        value: kg,
        type: HealthDataType.WEIGHT,
        startTime: when,
        endTime: when,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('Health writeWeight failed: $e');
      return false;
    }
  }

  Future<bool> writeHeightCm(double cm, {DateTime? at}) async {
    if (!await isConnected()) return false;
    await _ensureConfigured();
    final when = at ?? DateTime.now();
    try {
      return await _health.writeHealthData(
        value: cm / 100.0, // HealthKit height is meters
        type: HealthDataType.HEIGHT,
        startTime: when,
        endTime: when,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('Health writeHeight failed: $e');
      return false;
    }
  }

  Future<bool> writeMealNutrition({
    required String name,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String mealType = 'snack',
    DateTime? at,
  }) async {
    if (!await isConnected()) return false;
    await _ensureConfigured();
    final when = at ?? DateTime.now();
    final end = when.add(const Duration(minutes: 1));

    MealType mapped;
    switch (mealType) {
      case 'breakfast':
        mapped = MealType.BREAKFAST;
        break;
      case 'lunch':
        mapped = MealType.LUNCH;
        break;
      case 'dinner':
        mapped = MealType.DINNER;
        break;
      case 'snack':
        mapped = MealType.SNACK;
        break;
      default:
        mapped = MealType.UNKNOWN;
    }

    try {
      final mealOk = await _health.writeMeal(
        mealType: mapped,
        startTime: when,
        endTime: end,
        name: name,
        caloriesConsumed: calories.toDouble(),
        protein: protein.toDouble(),
        carbohydrates: carbs.toDouble(),
        fatTotal: fat.toDouble(),
      );
      if (mealOk) return true;
    } catch (e) {
      debugPrint('Health writeMeal failed, falling back: $e');
    }

    try {
      var ok = await _health.writeHealthData(
        value: calories.toDouble(),
        type: HealthDataType.DIETARY_ENERGY_CONSUMED,
        startTime: when,
        endTime: end,
        recordingMethod: RecordingMethod.manual,
      );
      ok &= await _health.writeHealthData(
        value: protein.toDouble(),
        type: HealthDataType.DIETARY_PROTEIN_CONSUMED,
        startTime: when,
        endTime: end,
        recordingMethod: RecordingMethod.manual,
      );
      ok &= await _health.writeHealthData(
        value: carbs.toDouble(),
        type: HealthDataType.DIETARY_CARBS_CONSUMED,
        startTime: when,
        endTime: end,
        recordingMethod: RecordingMethod.manual,
      );
      ok &= await _health.writeHealthData(
        value: fat.toDouble(),
        type: HealthDataType.DIETARY_FATS_CONSUMED,
        startTime: when,
        endTime: end,
        recordingMethod: RecordingMethod.manual,
      );
      return ok;
    } catch (e) {
      debugPrint('Health write nutrition failed: $e');
      return false;
    }
  }

  Future<List<HealthWeightSample>> readRecentWeights({int days = 30}) async {
    if (!await isConnected()) return const [];
    await _ensureConfigured();
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: start,
        endTime: now,
      );
      final samples = <HealthWeightSample>[];
      for (final p in points) {
        final value = p.value;
        if (value is NumericHealthValue) {
          samples.add(HealthWeightSample(
            weightKg: value.numericValue.toDouble(),
            date: p.dateFrom,
          ));
        }
      }
      samples.sort((a, b) => b.date.compareTo(a.date));
      return samples;
    } catch (e) {
      debugPrint('Health read weights failed: $e');
      return const [];
    }
  }

  Future<HealthDaySummary> readTodaySummary() async {
    if (!await isConnected()) {
      return const HealthDaySummary(steps: 0, activeEnergyKcal: 0);
    }
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    int steps = 0;
    double active = 0;
    double? weight;

    try {
      steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;
    } catch (_) {}

    try {
      final energyPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      for (final p in energyPoints) {
        final value = p.value;
        if (value is NumericHealthValue) {
          active += value.numericValue.toDouble();
        }
      }
    } catch (_) {}

    try {
      final weights = await readRecentWeights(days: 14);
      if (weights.isNotEmpty) weight = weights.first.weightKg;
    } catch (_) {}

    return HealthDaySummary(
      steps: steps,
      activeEnergyKcal: active,
      latestWeightKg: weight,
    );
  }
}
