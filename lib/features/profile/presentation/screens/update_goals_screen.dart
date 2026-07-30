import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

class UpdateGoalsScreen extends ConsumerStatefulWidget {
  const UpdateGoalsScreen({super.key});

  @override
  ConsumerState<UpdateGoalsScreen> createState() => _UpdateGoalsScreenState();
}

class _UpdateGoalsScreenState extends ConsumerState<UpdateGoalsScreen> {
  late String _goalType;
  late double _goalWeightKg;
  late double _weeklyLossKg;
  late String _dietMode;
  String _fastingStart = '20:00';
  String _fastingEnd = '12:00';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(authControllerProvider).user?.profile;
    _goalType = p?.goalType ?? 'lose_weight';
    _goalWeightKg = p?.goalWeightKg ?? 65;
    _weeklyLossKg = p?.weeklyLossKg ?? 0.5;
    _dietMode = p?.dietMode ?? 'normal';
    _fastingStart = _short(p?.fastingStart) ?? '20:00';
    _fastingEnd = _short(p?.fastingEnd) ?? '12:00';
  }

  String? _short(String? t) {
    if (t == null || t.isEmpty) return null;
    return t.length >= 5 ? t.substring(0, 5) : t;
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

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'goal_type': _goalType,
        'goal_weight_kg': _goalWeightKg,
        'diet_mode': _dietMode,
      };
      if (_goalType == 'lose_weight') {
        data['weekly_loss_kg'] = _weeklyLossKg;
      }
      if (_dietMode == 'intermittent_fasting') {
        data['fasting_start'] = _fastingStart;
        data['fasting_end'] = _fastingEnd;
      }

      final updated =
          await ref.read(profileRepositoryProvider).updateProfile(data);
      ref.read(authControllerProvider.notifier).updateUserProfile(updated);
      ref.invalidate(dashboardControllerProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals updated. Meal history unchanged.'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to update goals.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Update goals'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],
            const Text('GOAL TYPE', style: _labelStyle),
            const SizedBox(height: 8),
            for (final e in const [
              ('lose_weight', 'Lose weight'),
              ('maintain_weight', 'Maintain weight'),
              ('gain_weight', 'Gain weight / muscle'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Option(
                  title: e.$2,
                  selected: _goalType == e.$1,
                  onTap: () => setState(() => _goalType = e.$1),
                ),
              ),
            if (_goalType == 'lose_weight') ...[
              const SizedBox(height: 8),
              const Text('WEEKLY LOSS PACE', style: _labelStyle),
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
                onChanged: (v) =>
                    setState(() => _weeklyLossKg = (v * 100).roundToDouble() / 100),
              ),
            ],
            const SizedBox(height: 8),
            const Text('GOAL WEIGHT', style: _labelStyle),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Target', style: TextStyle(color: AppTheme.lightTextSecondary)),
                Text(
                  '${_goalWeightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryEmerald,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Slider(
              value: _goalWeightKg.clamp(30, 200),
              min: 30,
              max: 200,
              activeColor: AppTheme.primaryEmerald,
              onChanged: (v) =>
                  setState(() => _goalWeightKg = (v * 10).roundToDouble() / 10),
            ),
            const SizedBox(height: 12),
            const Text('TRACKING MODE', style: _labelStyle),
            const SizedBox(height: 8),
            _Option(
              title: 'Normal calorie tracking',
              subtitle: 'Eat anytime with a daily calorie goal',
              selected: _dietMode == 'normal',
              onTap: () => setState(() => _dietMode = 'normal'),
            ),
            const SizedBox(height: 8),
            _Option(
              title: 'Intermittent fasting',
              subtitle: 'Track fasting / eating window',
              selected: _dietMode == 'intermittent_fasting',
              onTap: () => setState(() => _dietMode = 'intermittent_fasting'),
            ),
            if (_dietMode == 'intermittent_fasting') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Fasting starts',
                      time: _fastingStart,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
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
                  : const Text('Save goals'),
            ),
          ],
        ),
      ),
    );
  }
}

const _labelStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 12,
  color: AppTheme.lightTextSecondary,
  letterSpacing: 0.8,
);

class _Option extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
                        color: selected ? AppTheme.primaryEmerald : AppTheme.lightTextPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
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
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
