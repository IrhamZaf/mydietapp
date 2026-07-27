import 'package:dio/dio.dart';
import 'package:my_diet_app/core/network/api_client.dart';
import 'package:my_diet_app/core/network/api_endpoints.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/dashboard/data/dashboard_model.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardModel> getDashboard() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.dashboard);
      final data = response.data['data'] as Map<String, dynamic>;
      return DashboardModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to load dashboard data');
    }
  }
}
