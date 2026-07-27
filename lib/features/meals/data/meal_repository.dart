import 'package:dio/dio.dart';
import 'package:my_diet_app/core/network/api_client.dart';
import 'package:my_diet_app/core/network/api_endpoints.dart';
import 'package:my_diet_app/core/network/api_exception.dart';

class MealRepository {
  final ApiClient _apiClient;

  MealRepository(this._apiClient);

  Future<void> logMeal({
    required String name,
    required String mealType,
    required int calories,
    required int protein,
    int carbs = 0,
    int fat = 0,
    String? portionSize,
  }) async {
    try {
      final payload = {
        'name': name,
        'meal_type': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'logged_at': DateTime.now().toIso8601String(),
      };
      if (portionSize != null) {
        payload['portion_size'] = portionSize;
      }

      await _apiClient.dio.post(
        ApiEndpoints.meals,
        data: payload,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to log meal');
    }
  }

  Future<List<dynamic>> getTodayMeals() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.mealsToday);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: 'Failed to fetch today meals');
    }
  }
}
