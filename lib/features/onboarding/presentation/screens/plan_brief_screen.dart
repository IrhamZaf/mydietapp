import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

class PlanBriefScreen extends ConsumerWidget {
  const PlanBriefScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final nutrition = state.planNutrition ?? {};
    final brief = state.planBrief ?? 'Your plan is ready. Follow your daily calorie and protein targets.';

    String numStr(String key, [String fallback = '—']) {
      final v = nutrition[key];
      if (v == null) return fallback;
      if (v is num) {
        return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      }
      return v.toString();
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Your Plan'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalized targets',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.planSource == 'ai'
                          ? 'Calculated from your profile, with an AI coaching brief.'
                          : 'Calculated from your profile (template brief — AI unavailable).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _StatChip(label: 'BMR', value: '${numStr('bmr')} kcal'),
                        const SizedBox(width: 8),
                        _StatChip(label: 'TDEE', value: '${numStr('tdee')} kcal'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatChip(label: 'Calories', value: numStr('calorie_target')),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Protein', value: '${numStr('protein_target')}g'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatChip(label: 'Carbs', value: '${numStr('carbs_target')}g'),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Fat', value: '${numStr('fat_target')}g'),
                      ],
                    ),
                    if (nutrition['weekly_loss_kg'] != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Pace',
                            value: '${numStr('weekly_loss_kg')} kg/wk',
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'ETA',
                            value: '${numStr('estimated_weeks')} wks',
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    const Text(
                      'PLAN BRIEF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.lightTextSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.lightBorder),
                      ),
                      child: Text(
                        brief,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  },
                  child: const Text('Start Tracking'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
