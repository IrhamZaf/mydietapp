import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/onboarding/data/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

class OnboardingState {
  final int step;
  final String gender;
  final DateTime? birthday;
  final double heightCm;
  final double weightKg;
  final double goalWeightKg;
  final String activityLevel;
  final String goalType;
  final String dietMode;
  final String fastingStart;
  final String fastingEnd;
  final bool isLoading;
  final String? errorMessage;

  OnboardingState({
    this.step = 0,
    this.gender = 'male',
    this.birthday,
    this.heightCm = 170.0,
    this.weightKg = 70.0,
    this.goalWeightKg = 65.0,
    this.activityLevel = 'moderately_active',
    this.goalType = 'lose_weight',
    this.dietMode = 'normal',
    this.fastingStart = '20:00',
    this.fastingEnd = '12:00',
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    int? step,
    String? gender,
    DateTime? birthday,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    String? activityLevel,
    String? goalType,
    String? dietMode,
    String? fastingStart,
    String? fastingEnd,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      dietMode: dietMode ?? this.dietMode,
      fastingStart: fastingStart ?? this.fastingStart,
      fastingEnd: fastingEnd ?? this.fastingEnd,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toApiData() {
    final Map<String, dynamic> data = {
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal_weight_kg': goalWeightKg,
      'activity_level': activityLevel,
      'goal_type': goalType,
      'diet_mode': dietMode,
    };

    if (birthday != null) {
      data['birthday'] = "${birthday!.year.toString().padLeft(4, '0')}-${birthday!.month.toString().padLeft(2, '0')}-${birthday!.day.toString().padLeft(2, '0')}";
    } else {
      final now = DateTime.now();
      data['birthday'] = "${now.year - 25}-01-01";
    }

    if (dietMode == 'intermittent_fasting') {
      data['fasting_start'] = fastingStart;
      data['fasting_end'] = fastingEnd;
    }

    return data;
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  final ProfileRepository _repository;
  final Ref _ref;

  OnboardingController(this._repository, this._ref) : super(OnboardingState());

  void setStep(int step) => state = state.copyWith(step: step);
  void setGender(String gender) => state = state.copyWith(gender: gender);
  void setBirthday(DateTime birthday) => state = state.copyWith(birthday: birthday);
  void setHeight(double height) => state = state.copyWith(heightCm: height);
  void setWeight(double weight) => state = state.copyWith(weightKg: weight);
  void setGoalWeight(double weight) => state = state.copyWith(goalWeightKg: weight);
  void setActivityLevel(String level) => state = state.copyWith(activityLevel: level);
  void setGoalType(String type) => state = state.copyWith(goalType: type);
  void setDietMode(String mode) => state = state.copyWith(dietMode: mode);
  void setFastingTimes(String start, String end) => state = state.copyWith(fastingStart: start, fastingEnd: end);

  Future<bool> submitProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedUser = await _repository.updateProfile(state.toApiData());
      _ref.read(authControllerProvider.notifier).updateUserProfile(updatedUser);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save profile.');
      return false;
    }
  }
}

final onboardingControllerProvider = StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return OnboardingController(repository, ref);
});
