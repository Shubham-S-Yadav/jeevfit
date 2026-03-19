import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/diet_plan_screen.dart';
import 'screens/home/exercise_plan_screen.dart';
import 'screens/home/timetable_screen.dart';
import 'screens/home/profile_screen.dart';
import 'screens/assessment/assessment_screen.dart';
import 'screens/library/exercise_library_screen.dart';
import 'screens/library/supplement_guide_screen.dart';
import 'screens/library/food_database_screen.dart';
import 'screens/library/breathing_screen.dart';
import 'screens/library/sleep_guide_screen.dart';
import 'screens/home/log_meal_screen.dart';
import 'screens/home/log_exercise_screen.dart';
import 'screens/home/log_progress_screen.dart';
import 'screens/home/tracking_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final auth = authState.state;

      if (auth == AuthState.initial || auth == AuthState.loading) {
        return path == '/' ? null : '/';
      }

      if (auth == AuthState.unauthenticated) {
        if (path == '/login' || path == '/register') return null;
        return '/login';
      }

      if (auth == AuthState.onboarding) {
        if (path == '/onboarding') return null;
        return '/onboarding';
      }

      if (auth == AuthState.authenticated) {
        if (path == '/' || path == '/login' || path == '/register' || path == '/onboarding') {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/assessment', builder: (_, __) => const AssessmentScreen()),
      GoRoute(path: '/library/exercises', builder: (_, __) => const ExerciseLibraryScreen()),
      GoRoute(path: '/library/supplements', builder: (_, __) => const SupplementGuideScreen()),
      GoRoute(path: '/library/foods', builder: (_, __) => const FoodDatabaseScreen()),
      GoRoute(path: '/library/breathing', builder: (_, __) => const BreathingScreen()),
      GoRoute(path: '/library/sleep', builder: (_, __) => const SleepGuideScreen()),
      GoRoute(path: '/log/meal', builder: (_, __) => const LogMealScreen()),
      GoRoute(path: '/log/exercise', builder: (_, __) => const LogExerciseScreen()),
      GoRoute(path: '/log/progress', builder: (_, __) => const LogProgressScreen()),
      GoRoute(path: '/tracking', builder: (_, __) => const TrackingHistoryScreen()),
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/diet', builder: (_, __) => const DietPlanScreen()),
          GoRoute(path: '/exercise', builder: (_, __) => const ExercisePlanScreen()),
          GoRoute(path: '/timetable', builder: (_, __) => const TimetableScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
