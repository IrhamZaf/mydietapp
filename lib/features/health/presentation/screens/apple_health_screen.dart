import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/health/presentation/health_providers.dart';
import 'package:my_diet_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

class AppleHealthScreen extends ConsumerStatefulWidget {
  const AppleHealthScreen({super.key});

  @override
  ConsumerState<AppleHealthScreen> createState() => _AppleHealthScreenState();
}

class _AppleHealthScreenState extends ConsumerState<AppleHealthScreen> {
  bool _busy = false;
  String? _message;
  bool _messageError = false;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final service = ref.read(healthServiceProvider);
    if (!service.isSupportedPlatform) {
      setState(() {
        _busy = false;
        _message = 'Apple Health is only available on iPhone.';
        _messageError = true;
      });
      return;
    }

    final ok = await service.connect();
    if (!ok) {
      setState(() {
        _busy = false;
        _message = 'Permission not granted. Enable MyDiet in Settings → Health → Data Access.';
        _messageError = true;
      });
      return;
    }

    // Import recent weights into backend.
    final weights = await service.readRecentWeights(days: 30);
    final weightRepo = ref.read(weightLogRepositoryProvider);
    var imported = 0;
    for (final sample in weights.take(14)) {
      try {
        await weightRepo.upsertWeight(
          weightKg: sample.weightKg,
          loggedDate: sample.date,
          notes: 'Imported from Apple Health',
          source: 'apple_health',
        );
        imported++;
      } catch (_) {}
    }

    // Push current profile height/weight to Health if present.
    final profile = ref.read(authControllerProvider).user?.profile;
    if (profile?.weightKg != null) {
      await service.writeWeightKg(profile!.weightKg!);
    }
    if (profile?.heightCm != null) {
      await service.writeHeightCm(profile!.heightCm!);
    }

    // Refresh profile weight from latest Health sample.
    if (weights.isNotEmpty) {
      try {
        await ref.read(profileRepositoryProvider).updateProfile({
          'weight_kg': weights.first.weightKg,
        });
      } catch (_) {}
    }

    ref.invalidate(healthConnectedProvider);
    ref.invalidate(healthTodaySummaryProvider);
    ref.invalidate(dashboardControllerProvider);

    setState(() {
      _busy = false;
      _message =
          'Connected. Imported $imported weight reading${imported == 1 ? '' : 's'} from Apple Health.';
      _messageError = false;
    });
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await ref.read(healthServiceProvider).disconnect();
    ref.invalidate(healthConnectedProvider);
    ref.invalidate(healthTodaySummaryProvider);
    setState(() {
      _busy = false;
      _message = 'Disconnected. Existing Health data was not deleted.';
      _messageError = false;
    });
  }

  Future<void> _syncNow() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final service = ref.read(healthServiceProvider);
    final summary = await service.readTodaySummary();
    final weights = await service.readRecentWeights(days: 7);
    final weightRepo = ref.read(weightLogRepositoryProvider);
    for (final sample in weights.take(7)) {
      try {
        await weightRepo.upsertWeight(
          weightKg: sample.weightKg,
          loggedDate: sample.date,
          source: 'apple_health',
        );
      } catch (_) {}
    }
    if (summary.latestWeightKg != null) {
      try {
        await ref.read(profileRepositoryProvider).updateProfile({
          'weight_kg': summary.latestWeightKg,
        });
      } catch (_) {}
    }
    ref.invalidate(healthTodaySummaryProvider);
    ref.invalidate(dashboardControllerProvider);
    setState(() {
      _busy = false;
      _message =
          'Synced. Today: ${summary.steps} steps, ${summary.activeEnergyKcal.round()} kcal active.';
      _messageError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectedAsync = ref.watch(healthConnectedProvider);
    final summaryAsync = ref.watch(healthTodaySummaryProvider);
    final connected = connectedAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Apple Health'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: AppTheme.primaryEmerald),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apple Health',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              connected ? 'Connected' : 'Not connected',
                              style: TextStyle(
                                color: connected ? AppTheme.primaryEmerald : AppTheme.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'MyDiet can read weight, steps, active energy, heart rate, sleep, and workouts — and write meals & weight you log back to Health.',
                    style: TextStyle(fontSize: 13, color: AppTheme.lightTextSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_messageError ? Colors.red : AppTheme.primaryEmerald)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _messageError ? Colors.red : AppTheme.primaryDarkEmerald,
                    fontSize: 13,
                  ),
                ),
              ),
            if (connected)
              summaryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (s) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Metric(label: 'Steps', value: '${s.steps}'),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Active',
                          value: '${s.activeEnergyKcal.round()} kcal',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Weight',
                          value: s.latestWeightKg != null
                              ? '${s.latestWeightKg!.toStringAsFixed(1)} kg'
                              : '—',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!connected)
              ElevatedButton(
                onPressed: _busy ? null : _connect,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Connect Apple Health'),
              )
            else ...[
              ElevatedButton(
                onPressed: _busy ? null : _syncNow,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Sync now'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _busy ? null : _disconnect,
                child: const Text('Disconnect'),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'After connecting, meals you log in MyDiet are written to Apple Health nutrition, and weight updates sync both ways.',
              style: TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.lightTextSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.lightTextPrimary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
