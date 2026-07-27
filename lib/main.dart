import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/auth/presentation/screens/login_screen.dart';
import 'package:my_diet_app/features/auth/presentation/screens/register_screen.dart';
import 'package:my_diet_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:my_diet_app/features/home/presentation/screens/main_shell_screen.dart';
import 'package:my_diet_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:my_diet_app/features/onboarding/presentation/screens/plan_brief_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyDietApp(),
    ),
  );
}

class MyDietApp extends StatelessWidget {
  const MyDietApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/plan-brief': (_) => const PlanBriefScreen(),
        '/dashboard': (_) => const MainShellScreen(),
        '/home': (_) => const MainShellScreen(),
      },
    );
  }
}
