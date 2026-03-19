import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding_steps.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      _profile = await _api.getProfile();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _editProfile() {
    if (_profile == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _EditProfileScreen(profile: _profile!, onSaved: _loadProfile),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              (user?['full_name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?['full_name'] ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text(user?['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_profile != null) ...[
                    // Body metrics
                    _buildSection('Body Metrics', [
                      _ProfileRow(label: 'Age', value: '${_profile!['age']} years'),
                      _ProfileRow(label: 'Height', value: '${_profile!['height_cm']} cm'),
                      _ProfileRow(label: 'Weight', value: '${_profile!['weight_kg']} kg'),
                      _ProfileRow(label: 'Gender', value: _profile!['gender'] ?? ''),
                      _ProfileRow(label: 'Region', value: (_profile!['region'] ?? '').toString().replaceAll('_', ' ')),
                      _ProfileRow(label: 'Activity', value: (_profile!['activity_level'] ?? '').toString().replaceAll('_', ' ')),
                    ]),
                    const SizedBox(height: 12),

                    // Diet preferences
                    _buildSection('Diet Preferences', [
                      _ProfileRow(label: 'Diet Type', value: (_profile!['dietary_preference'] ?? '').toString().replaceAll('_', ' ')),
                      _ProfileRow(label: 'Allergies', value: _formatList(_profile!['food_allergies'])),
                      _ProfileRow(label: "Can't Eat", value: _formatList(_profile!['foods_cant_eat'])),
                      _ProfileRow(label: 'Prefers', value: _formatList(_profile!['foods_prefer'])),
                      _ProfileRow(label: 'Meals/day', value: '${_profile!['meals_per_day'] ?? 3}'),
                    ]),
                    const SizedBox(height: 12),

                    // Exercise
                    _buildSection('Exercise', [
                      _ProfileRow(label: 'Location', value: (_profile!['exercise_location'] ?? 'home').toString().replaceAll('_', ' ')),
                      _ProfileRow(label: 'Time', value: '${_profile!['exercise_time_minutes'] ?? 30} min'),
                      _ProfileRow(label: 'Days/week', value: '${_profile!['exercise_days_per_week'] ?? 3}'),
                      _ProfileRow(label: 'Experience', value: (_profile!['exercise_experience'] ?? 'beginner').toString()),
                      _ProfileRow(label: 'Equipment', value: _formatList(_profile!['available_equipment'])),
                    ]),
                    const SizedBox(height: 12),

                    // Goals & Health
                    _buildSection('Goals & Health', [
                      _ProfileRow(label: 'Goals', value: _formatList(_profile!['fitness_goals'])),
                      _ProfileRow(label: 'Concerns', value: _formatList(_profile!['specific_concerns'])),
                      _ProfileRow(label: 'Conditions', value: _formatList(_profile!['medical_conditions'])),
                      _ProfileRow(label: 'Medications', value: _formatList(_profile!['current_medications'])),
                      _ProfileRow(label: 'Injuries', value: _formatList(_profile!['injuries'])),
                    ]),
                    const SizedBox(height: 16),

                    // Edit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Assessment
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                      title: const Text('New Health Assessment'),
                      subtitle: const Text('Upload a photo for AI analysis'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/assessment'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Logout', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('JeevFit v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
    );
  }

  String _formatList(dynamic val) {
    if (val == null) return 'None';
    if (val is List) return val.isEmpty ? 'None' : val.map((e) => e.toString().replaceAll('_', ' ')).join(', ');
    return val.toString();
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ==================== EDIT PROFILE SCREEN ====================

class _EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onSaved;
  const _EditProfileScreen({required this.profile, required this.onSaved});

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _api = ApiService();
  late Map<String, dynamic> _data;
  bool _isSaving = false;
  int _currentTab = 0;

  // Display name maps for multi-chip fields
  static const _goalOptions = ['Fat Loss', 'Muscle Gain', 'Maintenance', 'General Health', 'Stress Reduction', 'Better Sleep', 'Skin & Hair'];
  static const _concernOptions = ['Hair Fall', 'Acne / Skin Issues', 'Dark Circles', 'Low Energy', 'Poor Sleep', 'High Stress', 'Low Libido', 'Digestive Issues', 'Joint Pain', 'Back Pain', 'Weight Gain', 'Bloating', 'Brain Fog', 'Mood Swings'];
  static const _conditionOptions = ['Diabetes', 'Thyroid', 'PCOS/PCOD', 'Hypertension', 'High Cholesterol', 'Asthma', 'Heart Disease', 'Kidney Issues', 'Liver Issues', 'Arthritis', 'None'];
  static const _injuryOptions = ['Lower Back', 'Knee', 'Shoulder', 'Wrist', 'Ankle', 'Neck', 'Hip', 'None'];
  static const _allergyOptions = ['Peanuts', 'Dairy', 'Gluten', 'Soy', 'Eggs', 'Shellfish', 'Tree Nuts', 'Lactose'];
  static const _cantEatOptions = ['Onion', 'Garlic', 'Mushroom', 'Brinjal', 'Bitter Gourd', 'Fish', 'Mutton', 'Pork', 'Beef'];
  static const _preferOptions = ['Paneer', 'Curd', 'Rice', 'Roti', 'Dal', 'Chicken', 'Eggs', 'Fruits', 'Salad', 'Oats', 'Dosa', 'Idli'];
  static const _equipmentOptions = ['Yoga Mat', 'Dumbbells', 'Resistance Bands', 'Pull-up Bar', 'Kettlebell', 'Jump Rope', 'Ab Wheel', 'Bench', 'Full Gym Access'];

  @override
  void initState() {
    super.initState();
    // Copy profile and ensure all fields have safe defaults for onboarding widgets
    _data = Map<String, dynamic>.from(widget.profile);

    // Ensure all required fields exist with correct types
    _data['age'] = _data['age'] ?? 25;
    _data['gender'] = _data['gender'] ?? 'male';
    _data['height_cm'] = (_data['height_cm'] as num?)?.toDouble() ?? 170.0;
    _data['weight_kg'] = (_data['weight_kg'] as num?)?.toDouble() ?? 70.0;
    _data['region'] = _data['region'] ?? 'pan_india';
    _data['profession'] = _data['profession'] ?? '';
    _data['work_hours'] = _data['work_hours'] ?? '09:00-18:00';
    _data['activity_level'] = _data['activity_level'] ?? 'sedentary';
    _data['preferred_sleep_time'] = _data['preferred_sleep_time'] ?? '23:00';
    _data['preferred_wake_time'] = _data['preferred_wake_time'] ?? '07:00';
    _data['current_sleep_hours'] = (_data['current_sleep_hours'] as num?)?.toDouble() ?? 7.0;
    _data['dietary_preference'] = _data['dietary_preference'] ?? 'vegetarian';
    _data['meals_per_day'] = _data['meals_per_day'] ?? 3;
    _data['can_meal_prep'] = _data['can_meal_prep'] ?? false;
    _data['exercise_location'] = _data['exercise_location'] ?? 'home';
    _data['exercise_time_minutes'] = _data['exercise_time_minutes'] ?? 30;
    _data['exercise_days_per_week'] = _data['exercise_days_per_week'] ?? 3;
    _data['exercise_experience'] = _data['exercise_experience'] ?? 'beginner';
    _data['exercise_adherence_level'] = _data['exercise_adherence_level'] ?? 5;
    _data['diet_adherence_level'] = _data['diet_adherence_level'] ?? 5;
    _data['stress_level'] = _data['stress_level'] ?? 5;
    _data['water_intake_liters'] = (_data['water_intake_liters'] as num?)?.toDouble() ?? 2.0;
    _data['screen_time_hours'] = (_data['screen_time_hours'] as num?)?.toDouble() ?? 6.0;
    _data['smoking'] = _data['smoking'] ?? false;
    _data['alcohol'] = _data['alcohol'] ?? 'none';
    _data['current_diet'] = _data['current_diet'] ?? <String, String>{};

    // Convert snake_case lists back to display names for chip widgets
    _data['food_allergies'] = _toDisplayList(_data['food_allergies'], _allergyOptions);
    _data['foods_cant_eat'] = _toDisplayList(_data['foods_cant_eat'], _cantEatOptions);
    _data['foods_prefer'] = _toDisplayList(_data['foods_prefer'], _preferOptions);
    _data['available_equipment'] = _toDisplayList(_data['available_equipment'], _equipmentOptions);
    _data['fitness_goals'] = _toDisplayList(_data['fitness_goals'], _goalOptions);
    _data['specific_concerns'] = _toDisplayList(_data['specific_concerns'], _concernOptions);
    _data['medical_conditions'] = _toDisplayList(_data['medical_conditions'], _conditionOptions);
    _data['injuries'] = _toDisplayList(_data['injuries'], _injuryOptions);
  }

  List<String> _toDisplayList(dynamic stored, List<String> options) {
    if (stored == null) return [];
    if (stored is! List) return [];
    // Match snake_case stored values to display options
    return stored.map<String>((s) {
      final snake = s.toString().toLowerCase().replaceAll(' ', '_');
      final match = options.where((o) => o.toLowerCase().replaceAll(' & ', '_').replaceAll(' / ', '_').replaceAll('/', '_').replaceAll(' ', '_') == snake).firstOrNull;
      return match ?? s.toString();
    }).toList();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final data = Map<String, dynamic>.from(_data);
      // Transform display names to snake_case
      String toSnake(String s) => s.toLowerCase().replaceAll(' & ', '_').replaceAll(' / ', '_').replaceAll('/', '_').replaceAll(' ', '_');
      for (final key in ['fitness_goals', 'specific_concerns', 'medical_conditions', 'injuries']) {
        if (data[key] is List) {
          data[key] = (data[key] as List).map((e) => toSnake(e.toString())).toList();
        }
      }
      // Remove empty lists → null
      for (final key in data.keys.toList()) {
        if (data[key] is List && (data[key] as List).isEmpty) data[key] = null;
      }
      // Remove non-updatable fields
      data.remove('id');
      data.remove('user_id');
      data.remove('created_at');
      data.remove('updated_at');

      await _api.updateProfile(data);
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated! Regenerate plans to apply changes.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _update(String key, dynamic value) => setState(() => _data[key] = value);

  @override
  Widget build(BuildContext context) {
    final tabs = ['Basic', 'Diet', 'Exercise', 'Goals', 'Medical'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: tabs.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _currentTab == e.key,
                  onSelected: (_) => setState(() => _currentTab = e.key),
                  showCheckmark: false,
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                BasicInfoStep(data: _data, onUpdate: _update),
                DietPreferencesStep(data: _data, onUpdate: _update),
                ExerciseStep(data: _data, onUpdate: _update),
                HealthGoalsStep(data: _data, onUpdate: _update),
                MedicalHistoryStep(data: _data, onUpdate: _update),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
