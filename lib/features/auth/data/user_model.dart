class UserProfileModel {
  final String? gender;
  final String? birthday;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final String? activityLevel;
  final String? goalType;
  final String? dietMode;
  final String? fastingStart;
  final String? fastingEnd;
  final int? calorieTarget;
  final int? proteinTarget;

  UserProfileModel({
    this.gender,
    this.birthday,
    this.age,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.activityLevel,
    this.goalType,
    this.dietMode,
    this.fastingStart,
    this.fastingEnd,
    this.calorieTarget,
    this.proteinTarget,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      gender: json['gender'] as String?,
      birthday: json['birthday'] as String?,
      age: json['age'] as int?,
      heightCm: json['height_cm'] != null ? (json['height_cm'] as num).toDouble() : null,
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      goalWeightKg: json['goal_weight_kg'] != null ? (json['goal_weight_kg'] as num).toDouble() : null,
      activityLevel: json['activity_level'] as String?,
      goalType: json['goal_type'] as String?,
      dietMode: json['diet_mode'] as String?,
      fastingStart: json['fasting_start'] as String?,
      fastingEnd: json['fasting_end'] as String?,
      calorieTarget: json['calorie_target'] as int?,
      proteinTarget: json['protein_target'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (goalWeightKg != null) 'goal_weight_kg': goalWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (goalType != null) 'goal_type': goalType,
      if (dietMode != null) 'diet_mode': dietMode,
      if (fastingStart != null) 'fasting_start': fastingStart,
      if (fastingEnd != null) 'fasting_end': fastingEnd,
    };
  }

  bool get isProfileComplete =>
      gender != null &&
      heightCm != null &&
      weightKg != null &&
      goalWeightKg != null &&
      activityLevel != null &&
      goalType != null;
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final UserProfileModel? profile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      profile: json['profile'] != null ? UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>) : null,
    );
  }
}
