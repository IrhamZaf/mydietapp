class DashboardModel {
  final int caloriesConsumed;
  final int proteinConsumed;
  final int carbsConsumed;
  final int fatConsumed;
  final int fiberConsumed;

  final int caloriesRemaining;
  final int proteinRemaining;

  final int calorieTarget;
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;
  final int fiberTarget;

  final String dietMode;
  final bool isFasting;
  final String? fastingTimeRemaining;
  final double currentWeight;
  final double goalWeight;
  final double weightToLose;
  final int estimatedWeeks;
  final String? estimatedTargetDate;
  final int currentStreak;

  DashboardModel({
    required this.caloriesConsumed,
    required this.proteinConsumed,
    required this.carbsConsumed,
    required this.fatConsumed,
    required this.fiberConsumed,
    required this.caloriesRemaining,
    required this.proteinRemaining,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.fiberTarget,
    required this.dietMode,
    required this.isFasting,
    this.fastingTimeRemaining,
    required this.currentWeight,
    required this.goalWeight,
    required this.weightToLose,
    required this.estimatedWeeks,
    this.estimatedTargetDate,
    required this.currentStreak,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final fastingStatus = json['fasting_status'] as Map<String, dynamic>?;

    return DashboardModel(
      caloriesConsumed: (json['calories_consumed'] as num?)?.toInt() ?? 0,
      proteinConsumed: (json['protein_consumed'] as num?)?.toInt() ?? 0,
      carbsConsumed: (json['carbs_consumed'] as num?)?.toInt() ?? 0,
      fatConsumed: (json['fat_consumed'] as num?)?.toInt() ?? 0,
      fiberConsumed: (json['fiber_consumed'] as num?)?.toInt() ?? 0,

      caloriesRemaining: (json['calories_remaining'] as num?)?.toInt() ?? 0,
      proteinRemaining: (json['protein_remaining'] as num?)?.toInt() ?? 0,

      calorieTarget: (json['calorie_target'] as num?)?.toInt() ?? 2000,
      proteinTarget: (json['protein_target'] as num?)?.toInt() ?? 150,
      carbsTarget: (json['carbs_target'] as num?)?.toInt() ?? 225,
      fatTarget: (json['fat_target'] as num?)?.toInt() ?? 55,
      fiberTarget: (json['fiber_target'] as num?)?.toInt() ?? 30,

      dietMode: fastingStatus?['diet_mode'] as String? ?? 'standard',
      isFasting: fastingStatus?['is_fasting'] as bool? ?? false,
      fastingTimeRemaining: fastingStatus?['time_remaining'] as String?,
      currentWeight: (json['current_weight'] as num?)?.toDouble() ?? 70.0,
      goalWeight: (json['goal_weight'] as num?)?.toDouble() ?? 65.0,
      weightToLose: (json['weight_to_lose'] as num?)?.toDouble() ?? 0.0,
      estimatedWeeks: (json['estimated_weeks'] as num?)?.toInt() ?? 0,
      estimatedTargetDate: json['estimated_target_date'] as String?,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
    );
  }
}
