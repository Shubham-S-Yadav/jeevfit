import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LogExerciseScreen extends StatefulWidget {
  const LogExerciseScreen({super.key});

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  final _api = ApiService();
  bool _isSaving = false;

  String _exerciseType = 'strength';
  final List<Map<String, dynamic>> _exercises = [];
  int _durationMinutes = 30;
  bool _followedPlan = true;
  final _notesController = TextEditingController();

  // For adding exercises
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();

  final _exerciseTypes = [
    {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center},
    {'value': 'cardio', 'label': 'Cardio', 'icon': Icons.directions_run},
    {'value': 'yoga', 'label': 'Yoga', 'icon': Icons.self_improvement},
    {'value': 'hiit', 'label': 'HIIT', 'icon': Icons.flash_on},
    {'value': 'stretching', 'label': 'Stretching', 'icon': Icons.accessibility_new},
  ];

  void _addExercise() {
    if (_nameController.text.isEmpty) return;
    setState(() {
      _exercises.add({
        'name': _nameController.text,
        'sets': int.tryParse(_setsController.text) ?? 0,
        'reps': _repsController.text.isNotEmpty ? _repsController.text : '0',
      });
      _nameController.clear();
      _setsController.clear();
      _repsController.clear();
    });
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  Future<void> _save() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      // Rough calorie estimate: 5-10 cal per minute of exercise
      final calBurned = _durationMinutes * 7;
      await _api.logExercise({
        'exercise_type': _exerciseType,
        'exercises': _exercises,
        'duration_minutes': _durationMinutes,
        'calories_burned': calBurned,
        'followed_plan': _followedPlan,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout logged!'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
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

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise type selector
            const Text('Workout Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _exerciseTypes.map((et) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(et['icon'] as IconData, size: 16),
                    label: Text(et['label'] as String, style: const TextStyle(fontSize: 12)),
                    selected: _exerciseType == et['value'],
                    onSelected: (_) => setState(() => _exerciseType = et['value'] as String),
                    showCheckmark: false,
                    selectedColor: AppColors.exercise.withOpacity(0.2),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Duration slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$_durationMinutes min', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.exercise)),
              ],
            ),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              onChanged: (v) => setState(() => _durationMinutes = v.round()),
              activeColor: AppColors.exercise,
            ),
            const SizedBox(height: 12),

            // Add exercises
            const Text('Exercises', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Exercise name', isDense: true),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _setsController,
                    decoration: const InputDecoration(hintText: 'Sets', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(hintText: 'Reps', isDense: true),
                  ),
                ),
                IconButton(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add_circle, color: AppColors.exercise),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exercises list
            if (_exercises.isNotEmpty) ...[
              for (int i = 0; i < _exercises.length; i++)
                Card(
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.exercise.withOpacity(0.1),
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: AppColors.exercise, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(_exercises[i]['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: _exercises[i]['sets'] > 0 ? Text('${_exercises[i]['sets']} sets x ${_exercises[i]['reps']} reps') : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      onPressed: () => _removeExercise(i),
                    ),
                  ),
                ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No exercises added yet', style: TextStyle(color: AppColors.textSecondary))),
              ),

            const SizedBox(height: 20),

            // Followed plan toggle
            SwitchListTile(
              title: const Text('Followed exercise plan?'),
              value: _followedPlan,
              onChanged: (v) => setState(() => _followedPlan = v),
              activeColor: AppColors.exercise,
              contentPadding: EdgeInsets.zero,
            ),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(hintText: 'Notes (optional)', isDense: true),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
