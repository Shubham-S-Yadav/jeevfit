import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  String _location = 'home';
  String? _selectedMuscle;
  String? _selectedDifficulty;

  final _muscleGroups = ['Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Core'];
  final _difficulties = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _data = await _api.getExercises(
        location: _location,
        muscleGroup: _selectedMuscle?.toLowerCase(),
        difficulty: _selectedDifficulty,
      );
    } catch (e) {
      _error = 'Failed to load exercises. Please try again.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _difficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: Column(
        children: [
          // Location toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'home', label: Text('Home'), icon: Icon(Icons.home)),
                ButtonSegment(value: 'gym', label: Text('Gym'), icon: Icon(Icons.fitness_center)),
              ],
              selected: {_location},
              onSelectionChanged: (val) {
                setState(() => _location = val.first);
                _loadData();
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.exercise.withOpacity(0.15),
                selectedForegroundColor: AppColors.exercise,
              ),
            ),
          ),

          // Muscle group filter chips
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedMuscle == null,
                  onSelected: (_) {
                    setState(() => _selectedMuscle = null);
                    _loadData();
                  },
                  selectedColor: AppColors.exercise.withOpacity(0.15),
                  checkmarkColor: AppColors.exercise,
                ),
                const SizedBox(width: 8),
                for (final muscle in _muscleGroups) ...[
                  FilterChip(
                    label: Text(muscle),
                    selected: _selectedMuscle == muscle,
                    onSelected: (_) {
                      setState(() => _selectedMuscle = _selectedMuscle == muscle ? null : muscle);
                      _loadData();
                    },
                    selectedColor: AppColors.exercise.withOpacity(0.15),
                    checkmarkColor: AppColors.exercise,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          // Difficulty filter chips
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All Levels'),
                  selected: _selectedDifficulty == null,
                  onSelected: (_) {
                    setState(() => _selectedDifficulty = null);
                    _loadData();
                  },
                  selectedColor: AppColors.info.withOpacity(0.15),
                  checkmarkColor: AppColors.info,
                ),
                const SizedBox(width: 8),
                for (final diff in _difficulties) ...[
                  FilterChip(
                    label: Text(diff[0].toUpperCase() + diff.substring(1)),
                    selected: _selectedDifficulty == diff,
                    onSelected: (_) {
                      setState(() => _selectedDifficulty = _selectedDifficulty == diff ? null : diff);
                      _loadData();
                    },
                    selectedColor: _difficultyColor(diff).withOpacity(0.15),
                    checkmarkColor: _difficultyColor(diff),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildExerciseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    // API returns {muscle_group: [exercises]} dict — flatten to list
    final raw = _data?['exercises'];
    List exercises;
    if (raw is Map) {
      exercises = [];
      for (final entry in raw.entries) {
        final group = entry.key;
        if (entry.value is List) {
          for (final ex in entry.value) {
            if (ex is Map) {
              exercises.add({...Map<String, dynamic>.from(ex), 'muscle_group': group});
            }
          }
        }
      }
    } else if (raw is List) {
      exercises = raw;
    } else {
      exercises = [];
    }
    if (exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No exercises found for this filter.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final ex = exercises[index] as Map<String, dynamic>;
          return _buildExerciseCard(ex);
        },
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final difficulty = exercise['difficulty'] as String? ?? 'beginner';
    final muscles = (exercise['muscles'] as List?)?.join(', ') ?? exercise['muscle_group'] ?? '';
    final sets = exercise['sets'] ?? '';
    final reps = exercise['reps'] ?? '';
    final instructions = exercise['instructions'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.exercise.withOpacity(0.1),
          child: const Icon(Icons.fitness_center, color: AppColors.exercise, size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(exercise['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _difficultyColor(difficulty).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                difficulty[0].toUpperCase() + difficulty.substring(1),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _difficultyColor(difficulty)),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (muscles.isNotEmpty) ...[
                Icon(Icons.circle, size: 6, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(width: 4),
                Flexible(child: Text(muscles, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
              ],
              if (sets.toString().isNotEmpty && reps.toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('$sets sets x $reps reps', style: const TextStyle(fontSize: 12, color: AppColors.exercise)),
              ],
            ],
          ),
        ),
        children: [
          if (instructions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 4),
                  const Text('Instructions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(instructions, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                  if (exercise['alternatives'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Alternatives: ${(exercise['alternatives'] as List).join(', ')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.accent),
                    ),
                  ],
                  if (exercise['equipment'] != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final eq in (exercise['equipment'] is List ? exercise['equipment'] : [exercise['equipment']]))
                          Chip(
                            label: Text(eq.toString(), style: const TextStyle(fontSize: 11)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
