import 'package:dio/dio.dart';
import 'package:my_diet_app/core/network/api_client.dart';
import 'package:my_diet_app/core/network/api_endpoints.dart';
import 'package:my_diet_app/core/network/api_exception.dart';

class WeightLogRepository {
  final ApiClient _apiClient;

  WeightLogRepository(this._apiClient);

  Future<void> upsertWeight({
    required double weightKg,
    DateTime? loggedDate,
    String? notes,
    String source = 'manual',
  }) async {
    try {
      final date = loggedDate ?? DateTime.now();
      await _apiClient.dio.post(
        ApiEndpoints.weightLogs,
        data: {
          'weight_kg': weightKg,
          'logged_date':
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          if (notes != null) 'notes': notes,
          'source': source,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to save weight log');
    }
  }
}
