import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/ai_scanner/data/ai_scan_model.dart';
import 'package:my_diet_app/features/ai_scanner/data/ai_scanner_repository.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/health/presentation/health_providers.dart';
import 'package:my_diet_app/features/meals/data/meal_repository.dart';

final mealRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final health = ref.watch(healthServiceProvider);
  return MealRepository(apiClient, healthService: health);
});

final aiScannerRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiScannerRepository(apiClient);
});

class AiScannerState {
  final File? imageFile;
  final bool isScanning;
  final bool isLogging;
  final AiScanModel? scannedResult;
  final String? errorMessage;
  final String selectedMealType;
  final int scanGeneration;

  AiScannerState({
    this.imageFile,
    this.isScanning = false,
    this.isLogging = false,
    this.scannedResult,
    this.errorMessage,
    this.selectedMealType = 'lunch',
    this.scanGeneration = 0,
  });

  AiScannerState copyWith({
    File? imageFile,
    bool clearImage = false,
    bool? isScanning,
    bool? isLogging,
    AiScanModel? scannedResult,
    bool clearScannedResult = false,
    String? errorMessage,
    String? selectedMealType,
    int? scanGeneration,
  }) {
    return AiScannerState(
      imageFile: clearImage ? null : (imageFile ?? this.imageFile),
      isScanning: isScanning ?? this.isScanning,
      isLogging: isLogging ?? this.isLogging,
      scannedResult:
          clearScannedResult ? null : (scannedResult ?? this.scannedResult),
      errorMessage: errorMessage,
      selectedMealType: selectedMealType ?? this.selectedMealType,
      scanGeneration: scanGeneration ?? this.scanGeneration,
    );
  }
}

class AiScannerController extends StateNotifier<AiScannerState> {
  final AiScannerRepository _scannerRepository;
  final MealRepository _mealRepository;

  AiScannerController(this._scannerRepository, this._mealRepository)
      : super(AiScannerState());

  void setImage(File file) {
    state = state.copyWith(
      imageFile: file,
      clearScannedResult: true,
      errorMessage: null,
      scanGeneration: state.scanGeneration + 1,
    );
    scanImage();
  }

  void setMealType(String mealType) {
    state = state.copyWith(selectedMealType: mealType);
  }

  void updateScannedResult({
    required String foodName,
    required String portionSize,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) {
    state = state.copyWith(
      scannedResult: AiScanModel(
        foodName: foodName,
        portionSize: portionSize,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        confidence: state.scannedResult?.confidence ?? 'high',
        items: state.scannedResult?.items ?? [],
      ),
    );
  }

  Future<void> scanImage() async {
    if (state.imageFile == null) return;
    final generation = state.scanGeneration;
    final file = state.imageFile!;
    state = state.copyWith(isScanning: true, errorMessage: null);
    try {
      final result = await _scannerRepository.scanFoodImage(file);
      if (state.scanGeneration != generation) return;
      state = state.copyWith(isScanning: false, scannedResult: result);
    } on ApiException catch (e) {
      if (state.scanGeneration != generation) return;
      state = state.copyWith(isScanning: false, errorMessage: e.message);
    } catch (e) {
      if (state.scanGeneration != generation) return;
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'AI Scanner error. Please check backend connection.',
      );
    }
  }

  Future<bool> saveMeal() async {
    final result = state.scannedResult;
    if (result == null) return false;

    state = state.copyWith(isLogging: true, errorMessage: null);
    try {
      await _mealRepository.logMeal(
        name: result.foodName,
        mealType: state.selectedMealType,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        portionSize: result.portionSize,
        imageFile: state.imageFile,
      );
      state = state.copyWith(isLogging: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLogging: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLogging: false, errorMessage: 'Failed to log meal.');
      return false;
    }
  }

  void reset() {
    state = AiScannerState(scanGeneration: state.scanGeneration + 1);
  }
}

final aiScannerControllerProvider =
    StateNotifierProvider<AiScannerController, AiScannerState>((ref) {
  final scannerRepo = ref.watch(aiScannerRepositoryProvider);
  final mealRepo = ref.watch(mealRepositoryProvider);
  return AiScannerController(scannerRepo, mealRepo);
});
