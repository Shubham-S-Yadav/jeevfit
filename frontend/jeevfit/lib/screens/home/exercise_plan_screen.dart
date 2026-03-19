import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ExercisePlanScreen extends StatefulWidget {
  const ExercisePlanScreen({super.key});

  @override
  State<ExercisePlanScreen> createState() => _ExercisePlanScreenState();
}

class _ExercisePlanScreenState extends State<ExercisePlanScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  Map<String, dynamic>? _plan;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  final _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday - 1;
    _tabController = TabController(length: 7, vsync: this, initialIndex: today);
    _loadPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    if (ApiService.isGeneratingExercise) {
      setState(() { _isLoading = true; _error = null; });
      while (ApiService.isGeneratingExercise) {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
      }
      try {
        _plan = await _api.getActiveExercisePlan();
      } catch (e) {
        _error = 'Plan generation may have failed. Try again from Dashboard.';
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      _plan = await _api.getActiveExercisePlan();
    } catch (e) {
      _error = 'No active exercise plan. Generate one from the Dashboard!';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _regenerate() async {
    setState(() { _isLoading = true; _error = null; });
    ApiService.isGeneratingExercise = true;
    try {
      _plan = await _api.generateExercisePlan();
    } catch (e) {
      _error = 'Failed to generate: ${e.toString()}';
    }
    ApiService.isGeneratingExercise = false;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Plan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _regenerate, tooltip: 'Regenerate'),
        ],
      ),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Designing your workout plan...', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _regenerate,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Exercise Plan'),
                        ),
                      ],
                    ),
                  ),
                )
              : Builder(builder: (_) {
                  try {
                    return _buildPlanView();
                  } catch (e) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Error rendering plan: $e', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadPlan, child: const Text('Retry')),
                      ]),
                    ));
                  }
                }),
    );
  }

  Widget _buildPlanView() {
    if (_plan == null) return const Center(child: Text('No plan data'));
    final raw = _plan!['workout_plan'];
    final workoutPlan = raw is Map<String, dynamic> ? raw : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

    return Column(
      children: [
        // Plan info
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.exercise.withValues(alpha: 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoPill(icon: Icons.location_on, label: (_plan!['location'] ?? 'home').toString()),
              _InfoPill(icon: Icons.speed, label: (_plan!['difficulty'] ?? 'beginner').toString()),
              _InfoPill(icon: Icons.timer, label: '${_plan!['duration_minutes'] ?? 30} min'),
              _InfoPill(icon: Icons.calendar_today, label: '${_plan!['days_per_week'] ?? 3} days/wk'),
            ],
          ),
        ),

        // Day tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _dayLabels.map((d) => Tab(text: d)).toList(),
          labelColor: AppColors.exercise,
          indicatorColor: AppColors.exercise,
        ),

        // Workout for selected day
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _days.map((day) {
              final rawDay = workoutPlan[day];
              final dayPlan = rawDay is Map<String, dynamic> ? rawDay : (rawDay is Map ? Map<String, dynamic>.from(rawDay) : <String, dynamic>{});
              return _buildDayWorkout(day, dayPlan);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayWorkout(String day, Map<String, dynamic> dayPlan) {
    final isRestDay = dayPlan['is_rest_day'] ?? false;

    if (isRestDay) {
      final recovery = dayPlan['active_recovery'];
      String recoveryText;
      if (recovery is String) {
        recoveryText = recovery;
      } else if (recovery is Map) {
        recoveryText = recovery['activity']?.toString() ?? recovery.values.first?.toString() ?? 'Light stretching and walks recommended.';
      } else {
        recoveryText = 'Light stretching and walks recommended.';
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.self_improvement, size: 64, color: AppColors.sleep),
              const SizedBox(height: 16),
              const Text('Rest Day', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.sleep)),
              const SizedBox(height: 8),
              Text(
                recoveryText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final exercises = (dayPlan['exercises'] as List?) ?? [];
    final warmup = (dayPlan['warmup'] as List?) ?? [];
    final cooldown = (dayPlan['cooldown'] as List?) ?? [];
    final focus = dayPlan['focus'] ?? '';
    final totalDuration = dayPlan['total_duration_min'] ?? 0;
    final caloriesBurned = dayPlan['estimated_calories_burned'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Focus header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.exercise.withValues(alpha:0.8), AppColors.exercise],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(focus, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$totalDuration min  |  ~$caloriesBurned kcal', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const Icon(Icons.fitness_center, color: Colors.white, size: 36),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Warm-up
        if (warmup.isNotEmpty) ...[
          const Text('Warm-up', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning)),
          const SizedBox(height: 8),
          for (final w in warmup)
            ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 8, color: AppColors.warning),
              title: Text(w['name'] ?? '', style: const TextStyle(fontSize: 14)),
              trailing: Text(w['duration'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          const Divider(),
        ],

        // Exercises
        const Text('Exercises', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        for (int i = 0; i < exercises.length; i++)
          if (exercises[i] is Map<String, dynamic>)
            _buildExerciseCard(i + 1, exercises[i] as Map<String, dynamic>)
          else if (exercises[i] is Map)
            _buildExerciseCard(i + 1, Map<String, dynamic>.from(exercises[i] as Map)),

        // Cool-down
        if (cooldown.isNotEmpty) ...[
          const Divider(),
          const Text('Cool-down', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.info)),
          const SizedBox(height: 8),
          for (final c in cooldown)
            ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 8, color: AppColors.info),
              title: Text(c['name'] ?? '', style: const TextStyle(fontSize: 14)),
              trailing: Text(c['duration'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
        ],

        // Yoga plan
        if (_plan!['yoga_plan'] != null) ...[
          const SizedBox(height: 24),
          const Text('Yoga & Pranayama', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          for (final routine in [
            ...(_plan!['yoga_plan']['morning_routine'] as List? ?? []),
            ...(_plan!['yoga_plan']['evening_routine'] as List? ?? []),
            ...(_plan!['yoga_plan']['pranayama'] as List? ?? []),
          ])
            Card(
              child: ListTile(
                leading: const Icon(Icons.self_improvement, color: AppColors.stress),
                title: Text(routine['name'] ?? ''),
                subtitle: Text(routine['benefits'] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: Text(routine['duration'] ?? '', style: const TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildExerciseCard(int index, Map<String, dynamic> exercise) {
    final sets = exercise['sets'] ?? '';
    final reps = exercise['reps'] ?? '';
    final rest = exercise['rest_seconds'] ?? exercise['rest'] ?? '';
    final subtitle = [
      if (sets != '') '$sets sets',
      if (reps != '') 'x $reps reps',
      if (rest != '') 'Rest: ${rest}s',
    ].join('  |  ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.exercise.withValues(alpha: 0.1),
          child: Text('$index', style: const TextStyle(color: AppColors.exercise, fontWeight: FontWeight.bold)),
        ),
        title: Text(exercise['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exercise['instructions'] != null) ...[
                  const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(exercise['instructions'].toString(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                ],
                if (exercise['muscle_group'] != null)
                  Text('Muscle: ${exercise['muscle_group']}', style: const TextStyle(fontSize: 12, color: AppColors.info)),
                if (exercise['alternatives'] != null && exercise['alternatives'] is List) ...[
                  const SizedBox(height: 4),
                  Text('Alternatives: ${(exercise['alternatives'] as List).join(', ')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.exercise, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
