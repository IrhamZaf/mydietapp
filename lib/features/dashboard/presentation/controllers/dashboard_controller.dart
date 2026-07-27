import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/dashboard/data/dashboard_model.dart';
import 'package:my_diet_app/features/dashboard/data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient);
});

final dashboardControllerProvider = FutureProvider.autoDispose<DashboardModel>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getDashboard();
});
