import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/ai_scanner/data/ai_scan_model.dart';
import 'package:my_diet_app/features/ai_scanner/data/ai_scanner_repository.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/meals/data/meal_repository.dart';

final mealRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MealRepository(apiClient);
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

  AiScannerState({
    this.imageFile,
    this.isScanning = false,
    this.isLogging = false,
    this.scannedResult,
    this.errorMessage,
    this.selectedMealType = 'lunch',
  });

  AiScannerState copyWith({
    File? imageFile,
    bool? isScanning,
    bool? isLogging,
    AiScanModel? scannedResult,
    String? errorMessage,
    String? selectedMealType,
  }) {
    return AiScannerState(
      imageFile: imageFile ?? this.imageFile,
      isScanning: isScanning ?? this.isScanning,
      isLogging: isLogging ?? this.isLogging,
      scannedResult: scannedResult ?? this.scannedResult,
      errorMessage: errorMessage,
      selectedMealType: selectedMealType ?? this.selectedMealType,
    );
  }
}

class AiScannerController extends StateNotifier<AiScannerState> {
  final AiScannerRepository _scannerRepository;
  final MealRepository _mealRepository;

  AiScannerController(this._scannerRepository, this._mealRepository)
      : super(AiScannerState());

  void setImage(File file) {
    state = state.copyWith(imageFile: file, scannedResult: null, errorMessage: null);
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
    state = state.copyWith(isScanning: true, errorMessage: null);
    try {
      final result = await _scannerRepository.scanFoodImage(state.imageFile!);
      state = state.copyWith(isScanning: false, scannedResult: result);
    } on ApiException catch (e) {
      state = state.copyWith(isScanning: false, errorMessage: e.message);
    } catch (e) {
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
    state = AiScannerState();
  }
}

final aiScannerControllerProvider =
    StateNotifierProvider<AiScannerController, AiScannerState>((ref) {
  final scannerRepo = ref.watch(aiScannerRepositoryProvider);
  final mealRepo = ref.watch(mealRepositoryProvider);
  return AiScannerController(scannerRepo, mealRepo);
});
