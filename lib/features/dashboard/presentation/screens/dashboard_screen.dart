import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/ai_scanner/presentation/screens/ai_scanner_screen.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/dashboard/data/dashboard_model.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text(
          'Scan Meal with AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiScannerScreen()),
          );
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(dashboardControllerProvider.future),
          color: AppTheme.primaryEmerald,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row (Expanded to prevent overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name ?? 'Friend'} 👋',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Let\'s smash your nutrition goal today!',
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.lightTextSecondary),
                        onPressed: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                dashboardAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
                    ),
                  ),
                  error: (err, stack) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.refresh(dashboardControllerProvider),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                  data: (data) => _buildDashboardBody(context, data),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(BuildContext context, DashboardModel data) {
    final calorieRatio = (data.caloriesConsumed / (data.calorieTarget > 0 ? data.calorieTarget : 1)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak Badge & Diet Mode Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentOrange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${data.currentStreak} Day Streak!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.lightTextPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.dietMode == 'intermittent_fasting' ? 'Intermittent Fasting' : 'Standard Diet',
                  style: const TextStyle(color: AppTheme.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Main Calorie Ring Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'DAILY CALORIES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.lightTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: calorieRatio,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.caloriesRemaining}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              color: AppTheme.lightTextPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'kcal remaining',
                        style: TextStyle(fontSize: 13, color: AppTheme.lightTextSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroStat(label: 'Eaten', value: '${data.caloriesConsumed} kcal', valueColor: AppTheme.primaryEmerald),
                  Container(height: 30, width: 1, color: AppTheme.lightBorder),
                  _MacroStat(label: 'Target Goal', value: '${data.calorieTarget} kcal', valueColor: AppTheme.lightTextPrimary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Title: Daily Macro Breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Macro Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const Text(
              'Consumed / Target',
              style: TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Macro Cards 2x2 Grid (Protein, Carbs, Fat, Fiber)
        Row(
          children: [
            // Protein Card
            Expanded(
              child: _MacroProgressCard(
                label: 'PROTEIN',
                icon: Icons.fitness_center_rounded,
                consumed: data.proteinConsumed,
                target: data.proteinTarget,
                unit: 'g',
                color: AppTheme.secondaryTeal,
              ),
            ),
            const SizedBox(width: 12),

            // Carbo (Carbs) Card
            Expanded(
              child: _MacroProgressCard(
                label: 'CARBO',
                icon: Icons.grain_rounded,
                consumed: data.carbsConsumed,
                target: data.carbsTarget,
                unit: 'g',
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Fat Card
            Expanded(
              child: _MacroProgressCard(
                label: 'FAT',
                icon: Icons.egg_rounded,
                consumed: data.fatConsumed,
                target: data.fatTarget,
                unit: 'g',
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 12),

            // Fiber Card
            Expanded(
              child: _MacroProgressCard(
                label: 'FIBER',
                icon: Icons.grass_rounded,
                consumed: data.fiberConsumed,
                target: data.fiberTarget,
                unit: 'g',
                color: AppTheme.accentPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weight Progress Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.monitor_weight_outlined, color: AppTheme.accentOrange, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CURRENT WEIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.lightTextSecondary, letterSpacing: 0.8), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '${data.currentWeight} kg',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.lightTextPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightInputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Goal: ${data.goalWeight} kg',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.lightTextPrimary),
                    ),
                  ),
                ],
              ),
              if (data.weightToLose > 0 && data.estimatedTargetDate != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: AppTheme.primaryEmerald, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Target: -${data.weightToLose} kg • Est. Completion: ${data.estimatedTargetDate} (~${data.estimatedWeeks} wks)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Intermittent Fasting Card (If enabled)
        if (data.dietMode == 'intermittent_fasting') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPurple.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_rounded, color: AppTheme.accentPurple, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.isFasting ? 'Fasting Window Active' : 'Eating Window Active',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.lightTextPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.fastingTimeRemaining != null
                            ? '${data.isFasting ? 'Ends in' : 'Window ends in'}: ${data.fastingTimeRemaining}'
                            : 'Fasting active',
                        style: const TextStyle(fontSize: 13, color: AppTheme.accentPurple, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroProgressCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int consumed;
  final int target;
  final String unit;
  final Color color;

  const _MacroProgressCard({
    required this.label,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (consumed / (target > 0 ? target : 1)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppTheme.lightTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$consumed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
              ),
              Text(
                ' / $target$unit',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppTheme.lightTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MacroStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: valueColor)),
      ],
    );
  }
}
