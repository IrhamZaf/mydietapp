import 'package:my_diet_app/core/config/env_config.dart';

class ApiEndpoints {
  static String get baseUrl => EnvConfig.baseUrl;

  // Auth Endpoints
  static String get register => '/auth/register';
  static String get login => '/auth/login';
  static String get logout => '/auth/logout';
  static String get profile => '/profile';

  // Calculator Endpoint
  static String get calculator => '/calculator/calculate';

  // Dashboard Endpoint
  static String get dashboard => '/dashboard';

  // Meals Endpoints
  static String get meals => '/meals';
  static String get mealsToday => '/meals';

  // AI Scanner Endpoint
  static String get aiScan => '/food-detection';

  // Weight Logs Endpoints
  static String get weightLogs => '/weight-logs';

  // Statistics Endpoint
  static String get statistics => '/statistics';
}
