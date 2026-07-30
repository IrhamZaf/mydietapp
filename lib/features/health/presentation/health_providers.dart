import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/health/health_service.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/health/data/weight_log_repository.dart';

final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

final weightLogRepositoryProvider = Provider((ref) {
  return WeightLogRepository(ref.watch(apiClientProvider));
});

final healthConnectedProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(healthServiceProvider).isConnected();
});

final healthTodaySummaryProvider =
    FutureProvider.autoDispose<HealthDaySummary>((ref) async {
  final service = ref.watch(healthServiceProvider);
  if (!await service.isConnected()) {
    return const HealthDaySummary(steps: 0, activeEnergyKcal: 0);
  }
  return service.readTodaySummary();
});
