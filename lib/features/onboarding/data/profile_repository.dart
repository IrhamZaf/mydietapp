import 'package:dio/dio.dart';
import 'package:my_diet_app/core/network/api_client.dart';
import 'package:my_diet_app/core/network/api_endpoints.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/auth/data/user_model.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.profile,
        data: profileData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> calculateTargets() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.calculator);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to calculate nutrition targets');
    }
  }
}
