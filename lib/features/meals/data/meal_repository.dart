import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:my_diet_app/core/health/health_service.dart';
import 'package:my_diet_app/core/network/api_client.dart';
import 'package:my_diet_app/core/network/api_endpoints.dart';
import 'package:my_diet_app/core/network/api_exception.dart';

class MealRepository {
  final ApiClient _apiClient;
  final HealthService? _healthService;

  MealRepository(this._apiClient, {HealthService? healthService})
      : _healthService = healthService;

  Future<void> logMeal({
    required String name,
    required String mealType,
    required int calories,
    required int protein,
    int carbs = 0,
    int fat = 0,
    String? portionSize,
    File? imageFile,
  }) async {
    try {
      final loggedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final Map<String, dynamic> fields = {
        'name': name,
        'meal_type': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'logged_date': loggedDate,
        'logged_at': DateTime.now().toIso8601String(),
      };
      if (portionSize != null) {
        fields['portion_size'] = portionSize;
      }

      final Object data;
      if (imageFile != null) {
        final formMap = <String, dynamic>{...fields};
        formMap['image'] = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(RegExp(r'[\\/]')).last,
        );
        data = FormData.fromMap(formMap);
      } else {
        data = fields;
      }

      await _apiClient.dio.post(
        ApiEndpoints.meals,
        data: data,
      );

      try {
        await _healthService?.writeMealNutrition(
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          mealType: mealType,
        );
      } catch (_) {}
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to log meal');
    }
  }

  Future<List<dynamic>> getTodayMeals() {
    return getMealsForDate(DateTime.now());
  }

  Future<List<dynamic>> getMealsForDate(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _apiClient.dio.get(
        ApiEndpoints.mealsToday,
        queryParameters: {'date': dateStr},
      );
      final raw = response.data['data'] as List<dynamic>? ?? [];
      return raw.where((m) {
        if (m is! Map) return false;
        final logged = (m['logged_date'] ?? '').toString();
        return logged.isEmpty || logged.startsWith(dateStr);
      }).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to fetch meals');
    }
  }
}
