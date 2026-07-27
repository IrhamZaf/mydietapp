import 'dart:io';
import 'package:dio/dio.dart';
import 'package:my_diet_app/core/network/api_client.dart';
import 'package:my_diet_app/core/network/api_endpoints.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/ai_scanner/data/ai_scan_model.dart';

class AiScannerRepository {
  final ApiClient _apiClient;

  AiScannerRepository(this._apiClient);

  Future<AiScanModel> scanFoodImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.aiScan,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AiScanModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'AI failed to analyze the image. Please try again.');
    }
  }
}
