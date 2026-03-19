import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LogProgressScreen extends StatefulWidget {
  const LogProgressScreen({super.key});

  @override
  State<LogProgressScreen> createState() => _LogProgressScreenState();
}

class _LogProgressScreenState extends State<LogProgressScreen> {
  final _api = ApiService();
  bool _isSaving = false;

  double? _weightKg;
  double _sleepHours = 7.0;
  int _sleepQuality = 7;
  int _stressLevel = 5;
  int _energyLevel = 5;
  int _mood = 5;
  double _waterLiters = 2.0;
  int _skinRating = 5;
  int _hairRating = 5;
  final _notesController = TextEditingController();

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'sleep_hours': _sleepHours,
        'sleep_quality': _sleepQuality,
        'stress_level': _stressLevel,
        'energy_level': _energyLevel,
        'mood': _mood,
        'water_liters': _waterLiters,
        'skin_rating': _skinRating,
        'hair_rating': _hairRating,
      };
      if (_weightKg != null) data['weight_kg'] = _weightKg;
      if (_notesController.text.isNotEmpty) data['notes'] = _notesController.text;

      await _api.logProgress(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress logged!'), backgroundColor: AppColors.success),
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
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-in'),
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
            const Text('How was your day?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Track your daily metrics to see trends over time', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),

            // Weight (optional)
            TextField(
              decoration: const InputDecoration(
                labelText: 'Weight (optional)',
                suffixText: 'kg',
                hintText: 'e.g. 70.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _weightKg = double.tryParse(v),
            ),
            const SizedBox(height: 20),

            // Sleep
            _buildSlider(
              label: 'Sleep',
              value: _sleepHours,
              min: 2, max: 12, divisions: 20,
              suffix: '${_sleepHours.toStringAsFixed(1)} hrs',
              icon: Icons.bedtime,
              color: AppColors.sleep,
              onChanged: (v) => setState(() => _sleepHours = v),
            ),

            _buildRating(
              label: 'Sleep Quality',
              value: _sleepQuality,
              icon: Icons.star,
              color: AppColors.sleep,
              onChanged: (v) => setState(() => _sleepQuality = v),
            ),

            _buildRating(
              label: 'Stress Level',
              value: _stressLevel,
              icon: Icons.psychology,
              color: AppColors.stress,
              lowLabel: 'Calm',
              highLabel: 'Very Stressed',
              onChanged: (v) => setState(() => _stressLevel = v),
            ),

            _buildRating(
              label: 'Energy Level',
              value: _energyLevel,
              icon: Icons.bolt,
              color: AppColors.secondary,
              lowLabel: 'Tired',
              highLabel: 'Energized',
              onChanged: (v) => setState(() => _energyLevel = v),
            ),

            _buildRating(
              label: 'Mood',
              value: _mood,
              icon: Icons.mood,
              color: AppColors.accent,
              lowLabel: 'Low',
              highLabel: 'Great',
              onChanged: (v) => setState(() => _mood = v),
            ),

            _buildSlider(
              label: 'Water Intake',
              value: _waterLiters,
              min: 0, max: 6, divisions: 12,
              suffix: '${_waterLiters.toStringAsFixed(1)} L',
              icon: Icons.water_drop,
              color: AppColors.info,
              onChanged: (v) => setState(() => _waterLiters = v),
            ),

            _buildRating(
              label: 'Skin Condition',
              value: _skinRating,
              icon: Icons.face,
              color: AppColors.skin,
              lowLabel: 'Poor',
              highLabel: 'Glowing',
              onChanged: (v) => setState(() => _skinRating = v),
            ),

            _buildRating(
              label: 'Hair Condition',
              value: _hairRating,
              icon: Icons.content_cut,
              color: AppColors.hair,
              lowLabel: 'Poor',
              highLabel: 'Healthy',
              onChanged: (v) => setState(() => _hairRating = v),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(hintText: 'Any notes about today? (optional)', isDense: true),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(suffix, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildRating({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required ValueChanged<int> onChanged,
    String lowLabel = 'Low',
    String highLabel = 'High',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$value/10', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(lowLabel, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) => onChanged(v.round()),
                  activeColor: color,
                ),
              ),
              Text(highLabel, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
