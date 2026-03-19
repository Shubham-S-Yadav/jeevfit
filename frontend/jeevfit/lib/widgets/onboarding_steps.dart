import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

typedef OnUpdate = void Function(String key, dynamic value);

// ==================== STEP 1: Basic Info ====================
class BasicInfoStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const BasicInfoStep({super.key, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('This helps us create your personalized plan', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // Gender
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _GenderChip(label: 'Male', icon: Icons.male, selected: data['gender'] == 'male', onTap: () => onUpdate('gender', 'male')),
              const SizedBox(width: 12),
              _GenderChip(label: 'Female', icon: Icons.female, selected: data['gender'] == 'female', onTap: () => onUpdate('gender', 'female')),
              const SizedBox(width: 12),
              _GenderChip(label: 'Other', icon: Icons.transgender, selected: data['gender'] == 'other', onTap: () => onUpdate('gender', 'other')),
            ],
          ),
          const SizedBox(height: 24),

          // Age
          _SliderField(
            label: 'Age',
            value: (data['age'] as num).toDouble(),
            min: 14, max: 80,
            suffix: 'years',
            onChanged: (v) => onUpdate('age', v.round()),
          ),

          // Height
          _SliderField(
            label: 'Height',
            value: (data['height_cm'] as num).toDouble(),
            min: 120, max: 220,
            suffix: 'cm',
            onChanged: (v) => onUpdate('height_cm', v),
          ),

          // Weight
          _SliderField(
            label: 'Weight',
            value: (data['weight_kg'] as num).toDouble(),
            min: 30, max: 200,
            suffix: 'kg',
            onChanged: (v) => onUpdate('weight_kg', v),
          ),

          // Region
          const Text('Region', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final region in ['north_india', 'south_india', 'east_india', 'west_india', 'northeast_india', 'pan_india'])
                ChoiceChip(
                  label: Text(region.replaceAll('_', ' ').split(' ').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ')),
                  selected: data['region'] == region,
                  onSelected: (_) => onUpdate('region', region),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 2: Lifestyle ====================
class LifestyleStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const LifestyleStep({super.key, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Lifestyle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          TextFormField(
            initialValue: data['profession'] as String,
            decoration: const InputDecoration(labelText: 'Profession', hintText: 'e.g., Software Engineer, Teacher, Student'),
            onChanged: (v) => onUpdate('profession', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: data['work_hours'] as String,
            decoration: const InputDecoration(labelText: 'Work Hours', hintText: 'e.g., 09:00-18:00'),
            onChanged: (v) => onUpdate('work_hours', v),
          ),
          const SizedBox(height: 24),

          const Text('Activity Level', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          for (final level in [
            {'value': 'sedentary', 'label': 'Sedentary', 'desc': 'Desk job, no exercise'},
            {'value': 'lightly_active', 'label': 'Lightly Active', 'desc': 'Light exercise 1-3 days/week'},
            {'value': 'moderately_active', 'label': 'Moderately Active', 'desc': 'Moderate exercise 3-5 days/week'},
            {'value': 'very_active', 'label': 'Very Active', 'desc': 'Hard exercise 6-7 days/week'},
          ])
            RadioListTile<String>(
              title: Text(level['label']!),
              subtitle: Text(level['desc']!, style: const TextStyle(fontSize: 12)),
              value: level['value']!,
              groupValue: data['activity_level'] as String,
              onChanged: (v) => onUpdate('activity_level', v),
              dense: true,
              activeColor: AppColors.primary,
            ),

          const SizedBox(height: 16),

          // Sleep schedule
          const Text('Sleep Schedule', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: data['preferred_sleep_time'] as String?,
                  decoration: const InputDecoration(labelText: 'Sleep Time', hintText: '23:00'),
                  onChanged: (v) => onUpdate('preferred_sleep_time', v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: data['preferred_wake_time'] as String?,
                  decoration: const InputDecoration(labelText: 'Wake Time', hintText: '07:00'),
                  onChanged: (v) => onUpdate('preferred_wake_time', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SliderField(
            label: 'Current Sleep Hours',
            value: (data['current_sleep_hours'] as num?)?.toDouble() ?? 7.0,
            min: 3, max: 12, divisions: 18,
            suffix: 'hours',
            onChanged: (v) => onUpdate('current_sleep_hours', v),
          ),

          _SliderField(
            label: 'Stress Level',
            value: (data['stress_level'] as num?)?.toDouble() ?? 5.0,
            min: 1, max: 10, divisions: 9,
            suffix: '/10',
            onChanged: (v) => onUpdate('stress_level', v.round()),
          ),

          _SliderField(
            label: 'Daily Water Intake',
            value: (data['water_intake_liters'] as num?)?.toDouble() ?? 2.0,
            min: 0.5, max: 6, divisions: 11,
            suffix: 'liters',
            onChanged: (v) => onUpdate('water_intake_liters', v),
          ),

          _SliderField(
            label: 'Screen Time',
            value: (data['screen_time_hours'] as num?)?.toDouble() ?? 6.0,
            min: 1, max: 16, divisions: 15,
            suffix: 'hours/day',
            onChanged: (v) => onUpdate('screen_time_hours', v),
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 3: Diet Preferences ====================
class DietPreferencesStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const DietPreferencesStep({super.key, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diet Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          const Text('Dietary Type', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pref in ['vegetarian', 'non_vegetarian', 'eggetarian', 'vegan', 'jain'])
                ChoiceChip(
                  label: Text(pref.replaceAll('_', ' ').split(' ').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ')),
                  selected: data['dietary_preference'] == pref,
                  onSelected: (_) => onUpdate('dietary_preference', pref),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                ),
            ],
          ),
          const SizedBox(height: 24),

          _SliderField(
            label: 'Meals Per Day',
            value: (data['meals_per_day'] as num).toDouble(),
            min: 2, max: 7, divisions: 5,
            suffix: 'meals',
            onChanged: (v) => onUpdate('meals_per_day', v.round()),
          ),

          // Food allergies
          _MultiChipField(
            label: 'Food Allergies (if any)',
            options: ['Peanuts', 'Dairy', 'Gluten', 'Soy', 'Eggs', 'Shellfish', 'Tree Nuts', 'Lactose'],
            selected: List<String>.from(data['food_allergies'] ?? []),
            onChanged: (list) => onUpdate('food_allergies', list),
          ),

          // Foods can't eat
          _MultiChipField(
            label: 'Foods You Cannot/Will Not Eat',
            options: ['Onion', 'Garlic', 'Mushroom', 'Brinjal', 'Bitter Gourd', 'Fish', 'Mutton', 'Pork', 'Beef'],
            selected: List<String>.from(data['foods_cant_eat'] ?? []),
            onChanged: (list) => onUpdate('foods_cant_eat', list),
          ),

          // Foods prefer
          _MultiChipField(
            label: 'Foods You Love',
            options: ['Paneer', 'Curd', 'Rice', 'Roti', 'Dal', 'Chicken', 'Eggs', 'Fruits', 'Salad', 'Oats', 'Dosa', 'Idli'],
            selected: List<String>.from(data['foods_prefer'] ?? []),
            onChanged: (list) => onUpdate('foods_prefer', list),
          ),

          SwitchListTile(
            title: const Text('Can you meal prep?'),
            subtitle: const Text('Prepare meals in advance for the week'),
            value: data['can_meal_prep'] as bool,
            onChanged: (v) => onUpdate('can_meal_prep', v),
            activeColor: AppColors.primary,
          ),

          const SizedBox(height: 8),
          _SliderField(
            label: 'How strictly can you follow a diet plan?',
            value: (data['diet_adherence_level'] as num).toDouble(),
            min: 1, max: 10, divisions: 9,
            suffix: '/10',
            onChanged: (v) => onUpdate('diet_adherence_level', v.round()),
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 4: Current Diet ====================
class CurrentDietStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const CurrentDietStep({super.key, required this.data, required this.onUpdate});

  @override
  State<CurrentDietStep> createState() => _CurrentDietStepState();
}

class _CurrentDietStepState extends State<CurrentDietStep> {
  final _controllers = <String, TextEditingController>{};

  final _mealSlots = [
    {'key': 'early_morning', 'label': 'Early Morning', 'hint': 'e.g., Warm water, tea, soaked almonds'},
    {'key': 'breakfast', 'label': 'Breakfast', 'hint': 'e.g., 2 Paratha + curd, Poha, Idli-Sambhar'},
    {'key': 'mid_morning', 'label': 'Mid-Morning Snack', 'hint': 'e.g., Fruits, dry fruits, buttermilk'},
    {'key': 'lunch', 'label': 'Lunch', 'hint': 'e.g., 2 Roti + Dal + Sabzi + Rice + Salad'},
    {'key': 'evening_snack', 'label': 'Evening Snack', 'hint': 'e.g., Tea + biscuits, samosa, chana'},
    {'key': 'dinner', 'label': 'Dinner', 'hint': 'e.g., 2 Roti + Sabzi + Dal, Rice + Curry'},
    {'key': 'late_night', 'label': 'Late Night', 'hint': 'e.g., Milk, nothing'},
  ];

  @override
  void initState() {
    super.initState();
    final currentDiet = widget.data['current_diet'] as Map? ?? {};
    for (final slot in _mealSlots) {
      _controllers[slot['key']!] = TextEditingController(text: currentDiet[slot['key']] as String? ?? '');
    }
  }

  void _updateDiet() {
    final diet = <String, String>{};
    for (final entry in _controllers.entries) {
      if (entry.value.text.isNotEmpty) {
        diet[entry.key] = entry.value.text;
      }
    }
    widget.onUpdate('current_diet', diet);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What Do You Currently Eat?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('This helps us understand your current nutrition and suggest improvements', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          for (final slot in _mealSlots) ...[
            TextFormField(
              controller: _controllers[slot['key']],
              decoration: InputDecoration(
                labelText: slot['label'],
                hintText: slot['hint'],
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              maxLines: 2,
              onChanged: (_) => _updateDiet(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ==================== STEP 5: Exercise ====================
class ExerciseStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const ExerciseStep({super.key, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exercise Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          const Text('Where do you prefer to exercise?', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final loc in [
                {'value': 'home', 'label': 'Home', 'icon': Icons.home},
                {'value': 'gym', 'label': 'Gym', 'icon': Icons.fitness_center},
                {'value': 'both', 'label': 'Both', 'icon': Icons.swap_horiz},
                {'value': 'outdoor', 'label': 'Outdoor', 'icon': Icons.park},
              ])
                ChoiceChip(
                  avatar: Icon(loc['icon'] as IconData, size: 18, color: data['exercise_location'] == loc['value'] ? AppColors.primary : null),
                  label: Text(loc['label'] as String),
                  selected: data['exercise_location'] == loc['value'],
                  onSelected: (_) => onUpdate('exercise_location', loc['value']),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Experience Level', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          for (final exp in [
            {'value': 'beginner', 'label': 'Beginner', 'desc': 'New to exercise or returning after long break'},
            {'value': 'intermediate', 'label': 'Intermediate', 'desc': '6 months - 2 years of regular exercise'},
            {'value': 'advanced', 'label': 'Advanced', 'desc': '2+ years of consistent training'},
          ])
            RadioListTile<String>(
              title: Text(exp['label']!),
              subtitle: Text(exp['desc']!, style: const TextStyle(fontSize: 12)),
              value: exp['value']!,
              groupValue: data['exercise_experience'] as String,
              onChanged: (v) => onUpdate('exercise_experience', v),
              dense: true,
              activeColor: AppColors.primary,
            ),
          const SizedBox(height: 16),

          _SliderField(
            label: 'Exercise Time Available',
            value: (data['exercise_time_minutes'] as num).toDouble(),
            min: 10, max: 120, divisions: 11,
            suffix: 'min/session',
            onChanged: (v) => onUpdate('exercise_time_minutes', v.round()),
          ),

          _SliderField(
            label: 'Days Per Week',
            value: (data['exercise_days_per_week'] as num).toDouble(),
            min: 1, max: 7, divisions: 6,
            suffix: 'days',
            onChanged: (v) => onUpdate('exercise_days_per_week', v.round()),
          ),

          _MultiChipField(
            label: 'Available Equipment',
            options: [
              'Yoga Mat', 'Dumbbells', 'Resistance Bands', 'Pull-up Bar',
              'Kettlebell', 'Jump Rope', 'Ab Wheel', 'Bench',
              'Full Gym Access',
            ],
            selected: List<String>.from(data['available_equipment'] ?? []),
            onChanged: (list) => onUpdate('available_equipment', list),
          ),

          _SliderField(
            label: 'How consistently can you exercise?',
            value: (data['exercise_adherence_level'] as num).toDouble(),
            min: 1, max: 10, divisions: 9,
            suffix: '/10',
            onChanged: (v) => onUpdate('exercise_adherence_level', v.round()),
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 6: Health Goals ====================
class HealthGoalsStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const HealthGoalsStep({super.key, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What Are Your Goals?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Select all that apply', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          _MultiChipField(
            label: 'Fitness Goals',
            options: ['Fat Loss', 'Muscle Gain', 'Maintenance', 'General Health', 'Stress Reduction', 'Better Sleep', 'Skin & Hair'],
            selected: List<String>.from(data['fitness_goals'] ?? []),
            onChanged: (list) => onUpdate('fitness_goals', list),
          ),

          _MultiChipField(
            label: 'Specific Concerns',
            options: [
              'Hair Fall', 'Acne / Skin Issues', 'Dark Circles', 'Low Energy',
              'Poor Sleep', 'High Stress', 'Low Libido', 'Digestive Issues',
              'Joint Pain', 'Back Pain', 'Weight Gain', 'Bloating',
              'Brain Fog', 'Mood Swings',
            ],
            selected: List<String>.from(data['specific_concerns'] ?? []),
            onChanged: (list) => onUpdate('specific_concerns', list),
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 7: Medical History ====================
class MedicalHistoryStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const MedicalHistoryStep({super.key, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('This ensures safe recommendations', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          _MultiChipField(
            label: 'Medical Conditions (if any)',
            options: [
              'Diabetes', 'Thyroid', 'PCOS/PCOD', 'Hypertension',
              'High Cholesterol', 'Asthma', 'Heart Disease', 'Kidney Issues',
              'Liver Issues', 'Arthritis', 'None',
            ],
            selected: List<String>.from(data['medical_conditions'] ?? []),
            onChanged: (list) => onUpdate('medical_conditions', list),
          ),

          _MultiChipField(
            label: 'Injuries (if any)',
            options: [
              'Lower Back', 'Knee', 'Shoulder', 'Wrist',
              'Ankle', 'Neck', 'Hip', 'None',
            ],
            selected: List<String>.from(data['injuries'] ?? []),
            onChanged: (list) => onUpdate('injuries', list),
          ),

          const SizedBox(height: 16),
          TextFormField(
            initialValue: (data['current_medications'] as List?)?.join(', ') ?? '',
            decoration: const InputDecoration(
              labelText: 'Current Medications (if any)',
              hintText: 'e.g., Metformin, Thyroxine, none',
            ),
            onChanged: (v) => onUpdate('current_medications', v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Smoking'),
                  value: data['smoking'] as bool,
                  onChanged: (v) => onUpdate('smoking', v),
                  activeColor: AppColors.primary,
                  dense: true,
                ),
              ),
            ],
          ),

          const Text('Alcohol Consumption', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final level in ['none', 'occasional', 'regular'])
                ChoiceChip(
                  label: Text(level[0].toUpperCase() + level.substring(1)),
                  selected: data['alcohol'] == level,
                  onSelected: (_) => onUpdate('alcohol', level),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 8: Final Details ====================
class FinalDetailsStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final OnUpdate onUpdate;
  const FinalDetailsStep({super.key, required this.data, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final bmi = (data['weight_kg'] as num) / (((data['height_cm'] as num) / 100) * ((data['height_cm'] as num) / 100));
    String bmiCategory;
    Color bmiColor;
    if (bmi < 18.5) {
      bmiCategory = 'Underweight';
      bmiColor = AppColors.info;
    } else if (bmi < 25) {
      bmiCategory = 'Normal';
      bmiColor = AppColors.success;
    } else if (bmi < 30) {
      bmiCategory = 'Overweight';
      bmiColor = AppColors.warning;
    } else {
      bmiCategory = 'Obese';
      bmiColor = AppColors.error;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("You're Almost Done!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          // BMI Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bmiColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bmiColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your BMI', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(bmi.toStringAsFixed(1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: bmiColor)),
                    Text(bmiCategory, style: TextStyle(color: bmiColor, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                Icon(
                  bmiCategory == 'Normal' ? Icons.check_circle : Icons.info,
                  size: 48,
                  color: bmiColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Summary
          const Text('Profile Summary', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Age', value: '${data['age']} years'),
          _SummaryRow(label: 'Height', value: '${(data['height_cm'] as num).toStringAsFixed(0)} cm'),
          _SummaryRow(label: 'Weight', value: '${(data['weight_kg'] as num).toStringAsFixed(1)} kg'),
          _SummaryRow(label: 'Profession', value: data['profession'] as String),
          _SummaryRow(label: 'Activity', value: (data['activity_level'] as String).replaceAll('_', ' ')),
          _SummaryRow(label: 'Diet', value: (data['dietary_preference'] as String).replaceAll('_', ' ')),
          _SummaryRow(label: 'Exercise', value: '${data['exercise_location']} - ${data['exercise_time_minutes']}min x ${data['exercise_days_per_week']}days'),
          _SummaryRow(label: 'Goals', value: ((data['fitness_goals'] as List?)?.join(', ') ?? 'Not set').replaceAll('_', ' ')),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Our AI will analyze your data and create a personalized diet, exercise, and lifestyle plan just for you!',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== REUSABLE WIDGETS ====================

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _GenderChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : Colors.grey, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? AppColors.primary : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)} $suffix',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions ?? (max - min).toInt(),
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MultiChipField extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _MultiChipField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) {
                final newList = List<String>.from(selected);
                if (isSelected) {
                  newList.remove(option);
                } else {
                  newList.add(option);
                }
                onChanged(newList);
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
