import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/auth/data/user_model.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late String _goalType;
  late String _activityLevel;
  late String _dietMode;
  late double _goalWeightKg;
  late double _weightKg;
  late double _weeklyLossKg;
  String _fastingStart = '20:00';
  String _fastingEnd = '12:00';
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;
  bool _initialized = false;

  void _hydrateFromUser(UserModel? user) {
    final p = user?.profile;
    _goalType = p?.goalType ?? 'lose_weight';
    _activityLevel = p?.activityLevel ?? 'moderately_active';
    _dietMode = p?.dietMode ?? 'normal';
    _goalWeightKg = p?.goalWeightKg ?? 65;
    _weightKg = p?.weightKg ?? 70;
    _weeklyLossKg = p?.weeklyLossKg ?? 0.5;
    _fastingStart = p?.fastingStart?.substring(0, 5) ?? '20:00';
    _fastingEnd = p?.fastingEnd?.substring(0, 5) ?? '12:00';
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final data = <String, dynamic>{
        'goal_type': _goalType,
        'activity_level': _activityLevel,
        'diet_mode': _dietMode,
        'goal_weight_kg': _goalWeightKg,
        'weight_kg': _weightKg,
      };
      if (_goalType == 'lose_weight') {
        data['weekly_loss_kg'] = _weeklyLossKg;
      }
      if (_dietMode == 'intermittent_fasting') {
        data['fasting_start'] = _fastingStart;
        data['fasting_end'] = _fastingEnd;
      }

      final updated = await ref.read(profileRepositoryProvider).updateProfile(data);
      ref.read(authControllerProvider.notifier).updateUserProfile(updated);
      ref.invalidate(dashboardControllerProvider);

      setState(() {
        _message =
            'Goals updated. Meal history is unchanged. Calorie targets were recalculated.';
        _messageIsError = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _message = e.message;
        _messageIsError = true;
      });
    } catch (_) {
      setState(() {
        _message = 'Failed to update profile.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final parts = (isStart ? _fastingStart : _fastingEnd).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _fastingStart = formatted;
      } else {
        _fastingEnd = formatted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (!_initialized && user != null) {
      _hydrateFromUser(user);
    } else if (!_initialized) {
      _hydrateFromUser(null);
    }

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
            const SizedBox(height: 8),
            const Text(
              'Update goals anytime — meal & weight history stay intact.',
              style: TextStyle(fontSize: 13, color: AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 20),

            if (_message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_messageIsError ? Colors.red : AppTheme.primaryEmerald)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _messageIsError ? Colors.red : AppTheme.primaryDarkEmerald,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _sectionLabel('GOAL TYPE'),
            _option(
              title: 'Lose Weight',
              selected: _goalType == 'lose_weight',
              onTap: () => setState(() => _goalType = 'lose_weight'),
            ),
            _option(
              title: 'Maintain Weight',
              selected: _goalType == 'maintain_weight',
              onTap: () => setState(() => _goalType = 'maintain_weight'),
            ),
            _option(
              title: 'Gain Weight / Muscle',
              selected: _goalType == 'gain_weight',
              onTap: () => setState(() => _goalType = 'gain_weight'),
            ),

            if (_goalType == 'lose_weight') ...[
              const SizedBox(height: 16),
              _sectionLabel('WEEKLY LOSS PACE'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('kg / week', style: TextStyle(color: AppTheme.lightTextSecondary)),
                  Text(
                    '${_weeklyLossKg.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _weeklyLossKg.clamp(0.1, 1.0),
                min: 0.1,
                max: 1.0,
                divisions: 18,
                activeColor: AppTheme.primaryEmerald,
                onChanged: (v) => setState(() => _weeklyLossKg = (v * 100).roundToDouble() / 100),
              ),
            ],

            const SizedBox(height: 8),
            _sectionLabel('WEIGHT'),
            _sliderRow(
              label: 'Current',
              value: _weightKg,
              onChanged: (v) => setState(() => _weightKg = (v * 10).roundToDouble() / 10),
            ),
            _sliderRow(
              label: 'Goal',
              value: _goalWeightKg,
              onChanged: (v) => setState(() => _goalWeightKg = (v * 10).roundToDouble() / 10),
            ),

            const SizedBox(height: 8),
            _sectionLabel('ACTIVITY'),
            for (final entry in const [
              ('sedentary', 'Sedentary'),
              ('lightly_active', 'Lightly Active'),
              ('moderately_active', 'Moderately Active'),
              ('very_active', 'Very Active'),
              ('extra_active', 'Extra Active'),
            ])
              _option(
                title: entry.$2,
                selected: _activityLevel == entry.$1,
                onTap: () => setState(() => _activityLevel = entry.$1),
              ),

            const SizedBox(height: 8),
            _sectionLabel('TRACKING MODE'),
            _option(
              title: 'Normal calorie tracking',
              subtitle: 'Log meals anytime against a daily calorie goal',
              selected: _dietMode == 'normal',
              onTap: () => setState(() => _dietMode = 'normal'),
            ),
            _option(
              title: 'Intermittent fasting',
              subtitle: 'Track eating window with a fasting countdown',
              selected: _dietMode == 'intermittent_fasting',
              onTap: () => setState(() => _dietMode = 'intermittent_fasting'),
            ),

            if (_dietMode == 'intermittent_fasting') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _timeTile(
                      label: 'Fasting starts',
                      time: _fastingStart,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeTile(
                      label: 'Fasting ends',
                      time: _fastingEnd,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Save Goals'),
            ),
            const SizedBox(height: 8),
            Text(
              'Saving only updates your targets & diet mode. Logged meals are not deleted.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppTheme.lightTextSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _option({
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppTheme.primaryEmerald.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppTheme.primaryEmerald : AppTheme.lightBorder,
                width: selected ? 2 : 1,
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
                          fontSize: 14,
                          color: selected ? AppTheme.primaryEmerald : AppTheme.lightTextPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: selected ? AppTheme.primaryEmerald : AppTheme.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.lightTextSecondary)),
            Text(
              '${value.toStringAsFixed(1)} kg',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
            ),
          ],
        ),
        Slider(
          value: value.clamp(30, 200),
          min: 30,
          max: 200,
          activeColor: AppTheme.primaryEmerald,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _timeTile({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.lightTextSecondary)),
            const SizedBox(height: 6),
            Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
