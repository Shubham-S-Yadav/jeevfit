import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding_steps.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Collected data
  final Map<String, dynamic> _profileData = {
    'age': 25,
    'gender': 'male',
    'height_cm': 170.0,
    'weight_kg': 70.0,
    'region': 'pan_india',
    'profession': '',
    'work_hours': '09:00-18:00',
    'activity_level': 'sedentary',
    'preferred_sleep_time': '23:00',
    'preferred_wake_time': '07:00',
    'current_sleep_hours': 7.0,
    'dietary_preference': 'vegetarian',
    'food_allergies': <String>[],
    'foods_cant_eat': <String>[],
    'foods_prefer': <String>[],
    'meals_per_day': 3,
    'can_meal_prep': false,
    'monthly_food_budget': null,
    'current_diet': <String, String>{},
    'exercise_location': 'home',
    'available_equipment': <String>[],
    'exercise_time_minutes': 30,
    'exercise_days_per_week': 3,
    'exercise_experience': 'beginner',
    'fitness_goals': <String>[],
    'specific_concerns': <String>[],
    'medical_conditions': <String>[],
    'current_medications': <String>[],
    'injuries': <String>[],
    'stress_level': 5,
    'water_intake_liters': 2.0,
    'smoking': false,
    'alcohol': 'none',
    'screen_time_hours': 6.0,
    'diet_adherence_level': 5,
    'exercise_adherence_level': 5,
  };

  final List<String> _stepTitles = [
    'Basic Info',
    'Lifestyle',
    'Diet Preferences',
    'Current Diet',
    'Exercise',
    'Health Goals',
    'Medical History',
    'Final Details',
  ];

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submitProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _isSubmitting = true);
    try {
      // Clean up empty lists and transform display names to snake_case
      final data = Map<String, dynamic>.from(_profileData);
      String toSnake(String s) => s.toLowerCase().replaceAll(' & ', '_').replaceAll(' / ', '_').replaceAll('/', '_').replaceAll(' ', '_');
      for (final key in ['fitness_goals', 'specific_concerns', 'medical_conditions', 'injuries']) {
        if (data[key] is List) {
          data[key] = (data[key] as List).map((e) => toSnake(e.toString())).toList();
        }
      }
      data.removeWhere((key, value) => value is List && (value as List).isEmpty);
      data.removeWhere((key, value) => value is Map && (value as Map).isEmpty);
      data.removeWhere((key, value) => value == null);

      await ApiService().createProfile(data);
      ref.read(authProvider.notifier).completeOnboarding();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _stepTitles.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        leading: _currentStep > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentStep + 1}/${_stepTitles.length}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),

          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BasicInfoStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
                LifestyleStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
                DietPreferencesStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
                CurrentDietStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
                ExerciseStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
                HealthGoalsStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
                MedicalHistoryStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
                FinalDetailsStep(data: _profileData, onUpdate: (k, v) => setState(() => _profileData[k] = v)),
              ],
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_currentStep == _stepTitles.length - 1 ? 'Complete Setup' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
