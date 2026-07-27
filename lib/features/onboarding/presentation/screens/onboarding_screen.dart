import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Personalize Your Plan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = index <= state.step;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryEmerald : AppTheme.lightBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Error Display
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ),

            // Wizard Step Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildStepContent(context, state, controller),
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (state.step > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: state.isLoading ? null : () => controller.setStep(state.step - 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (state.step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              if (state.step < 3) {
                                controller.setStep(state.step + 1);
                              } else {
                                final success = await controller.submitProfile();
                                if (success && context.mounted) {
                                  Navigator.of(context).pushReplacementNamed('/dashboard');
                                }
                              }
                            },
                      child: state.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(state.step == 3 ? 'Complete Setup 🎉' : 'Next Step →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, OnboardingState state, OnboardingController controller) {
    switch (state.step) {
      case 0:
        return _StepGenderAndAge(state: state, controller: controller);
      case 1:
        return _StepMeasurements(state: state, controller: controller);
      case 2:
        return _StepActivityAndGoal(state: state, controller: controller);
      case 3:
        return _StepDietMode(state: state, controller: controller);
      default:
        return const SizedBox.shrink();
    }
  }
}

// STEP 1: Gender & Birthday
class _StepGenderAndAge extends StatelessWidget {
  final OnboardingState state;
  final OnboardingController controller;

  const _StepGenderAndAge({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Used to calculate your precise basal metabolic rate (BMR).',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),

        const Text('GENDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.lightTextSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 12),

        Row(
          children: [
            _GenderCard(
              title: 'Male',
              icon: Icons.male_rounded,
              isSelected: state.gender == 'male',
              onTap: () => controller.setGender('male'),
            ),
            const SizedBox(width: 16),
            _GenderCard(
              title: 'Female',
              icon: Icons.female_rounded,
              isSelected: state.gender == 'female',
              onTap: () => controller.setGender('female'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        const Text('BIRTHDAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.lightTextSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.birthday ?? DateTime(1998, 5, 15),
              firstDate: DateTime(1940),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
            );
            if (picked != null) {
              controller.setBirthday(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: AppTheme.primaryEmerald),
                const SizedBox(width: 14),
                Text(
                  state.birthday != null
                      ? DateFormat('MMMM dd, yyyy').format(state.birthday!)
                      : 'Select Birthday (Tap here)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: state.birthday != null ? AppTheme.lightTextPrimary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryEmerald.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryEmerald : AppTheme.lightBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: isSelected ? AppTheme.primaryEmerald : AppTheme.lightTextSecondary),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? AppTheme.primaryEmerald : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// STEP 2: Body Measurements
class _StepMeasurements extends StatelessWidget {
  final OnboardingState state;
  final OnboardingController controller;

  const _StepMeasurements({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body Measurements',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your current height, weight, and target goal weight.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),

        _SliderInput(
          label: 'HEIGHT',
          value: state.heightCm,
          min: 120,
          max: 220,
          unit: 'cm',
          onChanged: (val) => controller.setHeight(val.roundToDouble()),
        ),
        const SizedBox(height: 24),

        _SliderInput(
          label: 'CURRENT WEIGHT',
          value: state.weightKg,
          min: 30,
          max: 200,
          unit: 'kg',
          onChanged: (val) => controller.setWeight((val * 10).roundToDouble() / 10),
        ),
        const SizedBox(height: 24),

        _SliderInput(
          label: 'GOAL WEIGHT',
          value: state.goalWeightKg,
          min: 30,
          max: 200,
          unit: 'kg',
          onChanged: (val) => controller.setGoalWeight((val * 10).roundToDouble() / 10),
        ),
      ],
    );
  }
}

class _SliderInput extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.lightTextSecondary, letterSpacing: 0.8)),
            Text(
              '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} $unit',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryEmerald),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: AppTheme.primaryEmerald,
          inactiveColor: AppTheme.lightBorder,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// STEP 3: Activity Level & Goal Type
class _StepActivityAndGoal extends StatelessWidget {
  final OnboardingState state;
  final OnboardingController controller;

  const _StepActivityAndGoal({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity & Primary Goal',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your exercise frequency and weight target.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        const Text('GOAL TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.lightTextSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 10),

        _SelectOptionTile(
          title: '🔥 Lose Weight',
          subtitle: 'Moderate calorie deficit for sustainable fat loss',
          isSelected: state.goalType == 'lose_weight',
          onTap: () => controller.setGoalType('lose_weight'),
        ),
        const SizedBox(height: 10),
        _SelectOptionTile(
          title: '⚖️ Maintain Weight',
          subtitle: 'Stay at your current weight while building habit',
          isSelected: state.goalType == 'maintain_weight',
          onTap: () => controller.setGoalType('maintain_weight'),
        ),
        const SizedBox(height: 10),
        _SelectOptionTile(
          title: '💪 Gain Weight / Muscle',
          subtitle: 'Calorie surplus paired with high protein intake',
          isSelected: state.goalType == 'gain_weight',
          onTap: () => controller.setGoalType('gain_weight'),
        ),
        const SizedBox(height: 28),

        const Text('ACTIVITY LEVEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.lightTextSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 10),

        _SelectOptionTile(
          title: 'Desk Job / Sedentary',
          subtitle: 'Little to no exercise',
          isSelected: state.activityLevel == 'sedentary',
          onTap: () => controller.setActivityLevel('sedentary'),
        ),
        const SizedBox(height: 10),
        _SelectOptionTile(
          title: 'Lightly Active',
          subtitle: '1-3 workouts or sports per week',
          isSelected: state.activityLevel == 'lightly_active',
          onTap: () => controller.setActivityLevel('lightly_active'),
        ),
        const SizedBox(height: 10),
        _SelectOptionTile(
          title: 'Moderately Active',
          subtitle: '3-5 intense workouts per week',
          isSelected: state.activityLevel == 'moderately_active',
          onTap: () => controller.setActivityLevel('moderately_active'),
        ),
        const SizedBox(height: 10),
        _SelectOptionTile(
          title: 'Very Active',
          subtitle: '6-7 heavy workouts per week',
          isSelected: state.activityLevel == 'very_active',
          onTap: () => controller.setActivityLevel('very_active'),
        ),
      ],
    );
  }
}

// STEP 4: Diet Mode (Normal vs Intermittent Fasting)
class _StepDietMode extends StatelessWidget {
  final OnboardingState state;
  final OnboardingController controller;

  const _StepDietMode({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diet Protocol',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose if you want standard calorie tracking or Intermittent Fasting window countdown.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        _SelectOptionTile(
          title: '🥗 Normal Calorie Tracking',
          subtitle: 'Eat anytime throughout the day with daily calorie goal',
          isSelected: state.dietMode == 'normal',
          onTap: () => controller.setDietMode('normal'),
        ),
        const SizedBox(height: 12),
        _SelectOptionTile(
          title: '⏳ Intermittent Fasting (16/8)',
          subtitle: 'Track eating window with real-time countdown timer',
          isSelected: state.dietMode == 'intermittent_fasting',
          onTap: () => controller.setDietMode('intermittent_fasting'),
        ),

        if (state.dietMode == 'intermittent_fasting') ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FASTING WINDOW SETTINGS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryEmerald, letterSpacing: 0.8),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Fasting Starts',
                        time: state.fastingStart,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 20, minute: 0),
                          );
                          if (time != null) {
                            final formatted = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                            controller.setFastingTimes(formatted, state.fastingEnd);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Fasting Ends',
                        time: state.fastingEnd,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 12, minute: 0),
                          );
                          if (time != null) {
                            final formatted = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                            controller.setFastingTimes(state.fastingStart, formatted);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryEmerald.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryEmerald : AppTheme.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? AppTheme.primaryEmerald : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppTheme.primaryEmerald : AppTheme.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightInputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.lightTextSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primaryEmerald),
                const SizedBox(width: 6),
                Text(time, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightTextPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
