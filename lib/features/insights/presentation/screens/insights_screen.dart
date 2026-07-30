import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/health/presentation/health_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final healthSummary = ref.watch(healthTodaySummaryProvider).valueOrNull;
    final healthConnected = ref.watch(healthConnectedProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          ),
          error: (err, _) => Center(
            child: Text(err.toString(), style: const TextStyle(color: Colors.red)),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              const Text(
                'Insights',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      color: AppTheme.accentCoral,
                      label: 'Streak',
                      value: '${data.currentStreak} days',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.flag_rounded,
                      color: AppTheme.primaryBlue,
                      label: 'Daily goal',
                      value: '${data.calorieTarget} kcal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.monitor_weight_outlined,
                          color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weight progress',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.weightToLose > 0
                                ? '${data.currentWeight.toStringAsFixed(1)} → ${data.goalWeight.toStringAsFixed(1)} kg'
                                : '${data.currentWeight.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: AppTheme.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data.estimatedWeeks > 0)
                      Text(
                        '~${data.estimatedWeeks}w',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                  ],
                ),
              ),
              if (healthConnected && healthSummary != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.directions_walk_rounded,
                        color: AppTheme.macroProtein,
                        label: 'Steps today',
                        value: '${healthSummary.steps}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bolt_rounded,
                        color: AppTheme.accentOrange,
                        label: 'Active energy',
                        value: '${healthSummary.activeEnergyKcal.round()} kcal',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Macro targets',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    _MacroRow(
                      label: 'Protein',
                      value: '${data.proteinConsumed} / ${data.proteinTarget} g',
                      color: AppTheme.macroProtein,
                      progress: data.proteinTarget > 0
                          ? data.proteinConsumed / data.proteinTarget
                          : 0,
                    ),
                    const SizedBox(height: 10),
                    _MacroRow(
                      label: 'Carbs',
                      value: '${data.carbsConsumed} / ${data.carbsTarget} g',
                      color: AppTheme.macroCarbs,
                      progress: data.carbsTarget > 0
                          ? data.carbsConsumed / data.carbsTarget
                          : 0,
                    ),
                    const SizedBox(height: 10),
                    _MacroRow(
                      label: 'Fat',
                      value: '${data.fatConsumed} / ${data.fatTarget} g',
                      color: AppTheme.macroFat,
                      progress:
                          data.fatTarget > 0 ? data.fatConsumed / data.fatTarget : 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
