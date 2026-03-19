import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _timetable;
  bool _isLoading = true;
  String? _error;
  bool _showWeekday = true;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    if (ApiService.isGeneratingTimetable) {
      setState(() { _isLoading = true; _error = null; });
      while (ApiService.isGeneratingTimetable) {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
      }
      try {
        _timetable = await _api.getActiveTimetable();
      } catch (e) {
        _error = 'Timetable generation may have failed. Try again from Dashboard.';
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      _timetable = await _api.getActiveTimetable();
    } catch (e) {
      _error = 'No active timetable. Generate one from the Dashboard!';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _regenerate() async {
    setState(() { _isLoading = true; _error = null; });
    ApiService.isGeneratingTimetable = true;
    try {
      _timetable = await _api.generateTimetable();
    } catch (e) {
      _error = 'Failed to generate: ${e.toString()}';
    }
    ApiService.isGeneratingTimetable = false;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _regenerate, tooltip: 'Regenerate'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _regenerate,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Timetable'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildTimetableView(),
    );
  }

  Widget _buildTimetableView() {
    final schedule = _timetable!['schedule'] as Map<String, dynamic>? ?? {};
    final dayType = _showWeekday ? 'weekday' : 'weekend';
    final daySchedule = schedule[dayType] as Map<String, dynamic>? ?? {};

    // Sort by time
    final sortedEntries = daySchedule.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        // Toggle weekday/weekend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showWeekday = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showWeekday ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _showWeekday ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text('Weekday', style: TextStyle(
                        color: _showWeekday ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showWeekday = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showWeekday ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: !_showWeekday ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text('Weekend', style: TextStyle(
                        color: !_showWeekday ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Schedule timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final time = entry.key;
              final data = entry.value as Map<String, dynamic>;
              final activity = data['activity'] ?? '';
              final category = data['category'] ?? 'routine';
              final duration = data['duration_min'];
              final benefit = data['health_benefit'] ?? '';

              return _buildTimelineEntry(time, activity, category, duration, benefit, index == sortedEntries.length - 1);
            },
          ),
        ),

        // Goals
        if (_timetable!['weekly_goals'] != null || _timetable!['monthly_goals'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            child: ExpansionTile(
              title: const Text('Goals', style: TextStyle(fontWeight: FontWeight.w600)),
              children: [
                if (_timetable!['weekly_goals'] != null) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text('Weekly Goals', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.primary)),
                  ),
                  for (final goal in (_timetable!['weekly_goals'] as Map).entries)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, size: 20, color: AppColors.success),
                      title: Text('${goal.key}: ${goal.value}', style: const TextStyle(fontSize: 13)),
                    ),
                ],
                if (_timetable!['monthly_goals'] != null) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text('Monthly Goals', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondary)),
                  ),
                  for (final goal in (_timetable!['monthly_goals'] as Map).entries)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.flag_outlined, size: 20, color: AppColors.secondary),
                      title: Text('${goal.key}: ${goal.value}', style: const TextStyle(fontSize: 13)),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineEntry(String time, String activity, String category, dynamic duration, String benefit, bool isLast) {
    final categoryColors = {
      'routine': AppColors.textSecondary,
      'diet': AppColors.diet,
      'exercise': AppColors.exercise,
      'health': AppColors.accent,
      'work': AppColors.info,
    };
    final categoryIcons = {
      'routine': Icons.schedule,
      'diet': Icons.restaurant,
      'exercise': Icons.fitness_center,
      'health': Icons.favorite,
      'work': Icons.work,
    };

    final color = categoryColors[category] ?? AppColors.textSecondary;
    final icon = categoryIcons[category] ?? Icons.schedule;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 56,
            child: Text(time, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          ),

          // Timeline line
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: color.withOpacity(0.2))),
            ],
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        if (benefit.isNotEmpty)
                          Text(benefit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (duration != null) Text('${duration}m', style: TextStyle(fontSize: 11, color: color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
