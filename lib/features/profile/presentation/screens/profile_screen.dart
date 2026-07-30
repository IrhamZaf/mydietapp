import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/health/presentation/health_providers.dart';
import 'package:my_diet_app/features/health/presentation/screens/apple_health_screen.dart';
import 'package:my_diet_app/features/profile/presentation/screens/update_goals_screen.dart';
import 'package:my_diet_app/features/profile/presentation/screens/update_information_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _labelGoal(String? v) {
    switch (v) {
      case 'lose_weight':
        return 'Lose weight';
      case 'gain_weight':
        return 'Gain weight';
      case 'maintain_weight':
        return 'Maintain weight';
      default:
        return '—';
    }
  }

  String _labelActivity(String? v) {
    switch (v) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly active';
      case 'moderately_active':
        return 'Moderately active';
      case 'very_active':
        return 'Very active';
      case 'extra_active':
        return 'Extra active';
      default:
        return '—';
    }
  }

  String _labelDiet(String? v) {
    if (v == 'intermittent_fasting') return 'Intermittent fasting';
    if (v == 'normal') return 'Calorie tracking';
    return '—';
  }

  String _fmtKg(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} kg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final p = user?.profile;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              user?.name ?? 'Your profile',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            _Card(
              title: 'Personal information',
              children: [
                _Row(label: 'Gender', value: p?.gender == null ? '—' : p!.gender![0].toUpperCase() + p.gender!.substring(1)),
                _Row(label: 'Age', value: p?.age != null ? '${p!.age}' : '—'),
                _Row(label: 'Height', value: p?.heightCm != null ? '${p!.heightCm!.toStringAsFixed(0)} cm' : '—'),
                _Row(label: 'Current weight', value: _fmtKg(p?.weightKg)),
                _Row(label: 'Activity', value: _labelActivity(p?.activityLevel)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Update information'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpdateInformationScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            _Card(
              title: 'Apple Health',
              children: [
                _Row(
                  label: 'Status',
                  value: (ref.watch(healthConnectedProvider).valueOrNull ?? false)
                      ? 'Connected'
                      : 'Not connected',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.favorite_outline),
                label: const Text('Manage Apple Health'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppleHealthScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            _Card(
              title: 'Goals & tracking',
              children: [
                _Row(label: 'Goal', value: _labelGoal(p?.goalType)),
                _Row(label: 'Goal weight', value: _fmtKg(p?.goalWeightKg)),
                if (p?.goalType == 'lose_weight')
                  _Row(
                    label: 'Weekly pace',
                    value: p?.weeklyLossKg != null
                        ? '${p!.weeklyLossKg!.toStringAsFixed(2)} kg/week'
                        : '—',
                  ),
                _Row(label: 'Mode', value: _labelDiet(p?.dietMode)),
                if (p?.dietMode == 'intermittent_fasting')
                  _Row(
                    label: 'Fasting window',
                    value: '${_shortTime(p?.fastingStart)} – ${_shortTime(p?.fastingEnd)}',
                  ),
                _Row(
                  label: 'Daily calories',
                  value: p?.calorieTarget != null ? '${p!.calorieTarget} kcal' : '—',
                ),
                _Row(
                  label: 'Protein target',
                  value: p?.proteinTarget != null ? '${p!.proteinTarget} g' : '—',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Update goals'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpdateGoalsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Updating information or goals recalculates targets. Meal history is never deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _shortTime(String? t) {
    if (t == null || t.isEmpty) return '—';
    return t.length >= 5 ? t.substring(0, 5) : t;
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.lightTextSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppTheme.lightTextSecondary, fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
