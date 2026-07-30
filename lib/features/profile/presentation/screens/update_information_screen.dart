import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/health/presentation/health_providers.dart';
import 'package:my_diet_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

class UpdateInformationScreen extends ConsumerStatefulWidget {
  const UpdateInformationScreen({super.key});

  @override
  ConsumerState<UpdateInformationScreen> createState() =>
      _UpdateInformationScreenState();
}

class _UpdateInformationScreenState extends ConsumerState<UpdateInformationScreen> {
  late String _gender;
  DateTime? _birthday;
  late double _heightCm;
  late double _weightKg;
  late String _activityLevel;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(authControllerProvider).user?.profile;
    _gender = p?.gender ?? 'male';
    if (p?.birthday != null) {
      _birthday = DateTime.tryParse(p!.birthday!);
    }
    _heightCm = p?.heightCm ?? 170;
    _weightKg = p?.weightKg ?? 70;
    _activityLevel = p?.activityLevel ?? 'moderately_active';
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'gender': _gender,
        'height_cm': _heightCm,
        'weight_kg': _weightKg,
        'activity_level': _activityLevel,
      };
      if (_birthday != null) {
        data['birthday'] = DateFormat('yyyy-MM-dd').format(_birthday!);
      }

      final updated =
          await ref.read(profileRepositoryProvider).updateProfile(data);
      ref.read(authControllerProvider.notifier).updateUserProfile(updated);

      // Keep weight history + Apple Health in sync.
      try {
        await ref.read(weightLogRepositoryProvider).upsertWeight(
              weightKg: _weightKg,
              source: 'profile',
            );
      } catch (_) {}
      try {
        final health = ref.read(healthServiceProvider);
        if (await health.isConnected()) {
          await health.writeWeightKg(_weightKg);
          await health.writeHeightCm(_heightCm);
        }
      } catch (_) {}

      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(healthTodaySummaryProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Information updated. Meal history unchanged.'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to update information.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Update information'),
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
            const Text('GENDER', style: _labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Chip(
                    label: 'Male',
                    selected: _gender == 'male',
                    onTap: () => setState(() => _gender = 'male'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Chip(
                    label: 'Female',
                    selected: _gender == 'female',
                    onTap: () => setState(() => _gender = 'female'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('BIRTHDAY', style: _labelStyle),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _birthday ?? DateTime(1998, 1, 1),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                );
                if (picked != null) setState(() => _birthday = picked);
              },
              child: Text(
                _birthday != null
                    ? DateFormat('MMMM dd, yyyy').format(_birthday!)
                    : 'Select birthday',
              ),
            ),
            const SizedBox(height: 20),
            _SliderBlock(
              label: 'HEIGHT',
              valueLabel: '${_heightCm.round()} cm',
              value: _heightCm,
              min: 120,
              max: 220,
              onChanged: (v) => setState(() => _heightCm = v.roundToDouble()),
            ),
            _SliderBlock(
              label: 'CURRENT WEIGHT',
              valueLabel: '${_weightKg.toStringAsFixed(1)} kg',
              value: _weightKg,
              min: 30,
              max: 200,
              onChanged: (v) =>
                  setState(() => _weightKg = (v * 10).roundToDouble() / 10),
            ),
            const Text('ACTIVITY LEVEL', style: _labelStyle),
            const SizedBox(height: 8),
            for (final e in const [
              ('sedentary', 'Sedentary'),
              ('lightly_active', 'Lightly active'),
              ('moderately_active', 'Moderately active'),
              ('very_active', 'Very active'),
              ('extra_active', 'Extra active'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Chip(
                  label: e.$2,
                  selected: _activityLevel == e.$1,
                  onTap: () => setState(() => _activityLevel = e.$1),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Save information'),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primaryEmerald.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryEmerald : AppTheme.lightBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.primaryEmerald : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderBlock extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderBlock({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
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
            Text(label, style: _labelStyle),
            Text(
              valueLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryEmerald,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: AppTheme.primaryEmerald,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
