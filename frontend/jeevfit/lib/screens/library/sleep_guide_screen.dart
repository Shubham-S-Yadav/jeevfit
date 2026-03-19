import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SleepGuideScreen extends ConsumerStatefulWidget {
  const SleepGuideScreen({super.key});

  @override
  ConsumerState<SleepGuideScreen> createState() => _SleepGuideScreenState();
}

class _SleepGuideScreenState extends ConsumerState<SleepGuideScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  String? _selectedProfession;

  final _professions = ['IT Corporate', 'Night Shift', 'Startup Founder'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _data = await _api.getSleepProtocols(profession: _selectedProfession?.toLowerCase().replaceAll(' ', '_'));
    } catch (e) {
      _error = 'Failed to load sleep guide. Please try again.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Guide')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bedtime, size: 64, color: AppColors.textSecondary),
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
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScienceSection(),
                        const SizedBox(height: 20),
                        _buildCoreRulesSection(),
                        const SizedBox(height: 20),
                        _buildProfessionSchedules(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildScienceSection() {
    final science = _data?['science'] as Map<String, dynamic>? ?? {};
    final recommendedHours = science['recommended_hours'] ?? '7-9 hours';
    final sleepCycles = science['sleep_cycles'] ?? 'Each cycle lasts ~90 minutes. Aim for 5-6 complete cycles.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sleep.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.science, color: AppColors.sleep, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sleep Science', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                      SizedBox(height: 2),
                      Text('Understanding your sleep', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sleep.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.sleep, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recommended Sleep', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(recommendedHours.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.sleep)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.loop, color: AppColors.info, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sleep Cycles', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(sleepCycles.toString(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Additional science info from API
            if (science['stages'] != null) ...[
              const SizedBox(height: 12),
              const Text('Sleep Stages', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              for (final stage in (science['stages'] as List))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.sleep.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stage is Map ? '${stage['name']}: ${stage['description']}' : stage.toString(),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoreRulesSection() {
    final rules = (_data?['rules'] as List?) ?? [];
    final ruleIcons = {
      'light': Icons.light_mode,
      'temperature': Icons.thermostat,
      'timing': Icons.schedule,
      'substances': Icons.no_drinks,
      'supplements': Icons.medication,
      'environment': Icons.bedroom_parent,
      'routine': Icons.repeat,
    };
    final ruleColors = {
      'light': AppColors.warning,
      'temperature': AppColors.info,
      'timing': AppColors.primary,
      'substances': AppColors.error,
      'supplements': AppColors.accent,
      'environment': AppColors.sleep,
      'routine': AppColors.stress,
    };

    // Fallback if API returns no rules
    final displayRules = rules.isNotEmpty
        ? rules
        : [
            {'key': 'light', 'title': 'Light Management', 'description': 'Get morning sunlight within 30 min of waking. Dim lights 2 hours before bed. Use blue-light blockers after sunset.'},
            {'key': 'temperature', 'title': 'Temperature', 'description': 'Keep bedroom at 18-20°C (65-68°F). Take a warm shower 1-2 hours before bed to trigger temperature drop.'},
            {'key': 'timing', 'title': 'Timing', 'description': 'Go to bed and wake up at the same time every day. Aim for sleep onset by 10:30 PM for Indians.'},
            {'key': 'substances', 'title': 'Substances', 'description': 'No caffeine after 2 PM. Limit alcohol - it fragments sleep. Avoid heavy meals within 3 hours of bedtime.'},
            {'key': 'supplements', 'title': 'Supplements', 'description': 'Magnesium Glycinate (200-400mg), Ashwagandha (300-600mg), or L-Theanine (200mg) can help if needed.'},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Core Sleep Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final rule in displayRules)
          _buildRuleCard(
            rule as Map<String, dynamic>,
            ruleIcons[rule['key']] ?? Icons.check_circle,
            ruleColors[rule['key']] ?? AppColors.sleep,
          ),
      ],
    );
  }

  Widget _buildRuleCard(Map<String, dynamic> rule, IconData icon, Color color) {
    final title = rule['title'] as String? ?? '';
    final description = rule['description'] as String? ?? '';
    final tips = (rule['tips'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty)
                  Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final tip in tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, size: 16, color: color),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tip.toString(), style: const TextStyle(fontSize: 13, height: 1.4))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionSchedules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profession Schedules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Sleep routines tailored to your work', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 12),

        // Profession filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedProfession == null,
                onSelected: (_) {
                  setState(() => _selectedProfession = null);
                  _loadData();
                },
                selectedColor: AppColors.sleep.withOpacity(0.15),
                checkmarkColor: AppColors.sleep,
              ),
              const SizedBox(width: 8),
              for (final prof in _professions) ...[
                FilterChip(
                  label: Text(prof),
                  selected: _selectedProfession == prof,
                  onSelected: (_) {
                    setState(() => _selectedProfession = _selectedProfession == prof ? null : prof);
                    _loadData();
                  },
                  selectedColor: AppColors.sleep.withOpacity(0.15),
                  checkmarkColor: AppColors.sleep,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Schedule cards
        _buildScheduleCards(),
      ],
    );
  }

  Widget _buildScheduleCards() {
    final schedules = (_data?['schedules'] as List?) ?? [];

    // Fallback schedules
    final displaySchedules = schedules.isNotEmpty
        ? schedules
        : [
            {
              'profession': 'IT Corporate',
              'icon': 'laptop',
              'timeline': [
                {'time': '10:00 PM', 'activity': 'Screen off, dim lights'},
                {'time': '10:15 PM', 'activity': 'Light stretching / Yoga Nidra'},
                {'time': '10:30 PM', 'activity': 'Lights out'},
                {'time': '6:00 AM', 'activity': 'Wake up, sunlight exposure'},
                {'time': '6:15 AM', 'activity': '5 min pranayama'},
              ],
            },
            {
              'profession': 'Night Shift',
              'icon': 'nightlight',
              'timeline': [
                {'time': '7:00 AM', 'activity': 'Wear blue-light blockers on commute'},
                {'time': '7:30 AM', 'activity': 'Blackout curtains, cool room'},
                {'time': '8:00 AM', 'activity': 'Sleep onset'},
                {'time': '3:00 PM', 'activity': 'Wake up, bright light exposure'},
                {'time': '3:30 PM', 'activity': 'Exercise + healthy meal'},
              ],
            },
            {
              'profession': 'Startup Founder',
              'icon': 'rocket_launch',
              'timeline': [
                {'time': '9:30 PM', 'activity': 'Brain dump - write tomorrow\'s tasks'},
                {'time': '10:00 PM', 'activity': 'No screens, relaxation routine'},
                {'time': '10:15 PM', 'activity': 'Magnesium + Ashwagandha'},
                {'time': '10:30 PM', 'activity': 'Lights out'},
                {'time': '5:30 AM', 'activity': 'Wake up, 10 min meditation'},
              ],
            },
          ];

    final filtered = _selectedProfession == null
        ? displaySchedules
        : displaySchedules.where((s) {
            final prof = (s as Map<String, dynamic>)['profession'] as String? ?? '';
            return prof.toLowerCase() == _selectedProfession!.toLowerCase();
          }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No schedules available.', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Column(
      children: [
        for (final schedule in filtered)
          _buildTimelineCard(schedule as Map<String, dynamic>),
      ],
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> schedule) {
    final profession = schedule['profession'] as String? ?? '';
    final timeline = (schedule['timeline'] as List?) ?? [];
    final profColors = {
      'IT Corporate': AppColors.info,
      'Night Shift': AppColors.stress,
      'Startup Founder': AppColors.secondary,
    };
    final color = profColors[profession] ?? AppColors.sleep;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.work, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(profession, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline
            for (int i = 0; i < timeline.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline line
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < timeline.length - 1)
                          Container(width: 2, height: 32, color: color.withOpacity(0.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              (timeline[i] as Map<String, dynamic>)['time']?.toString() ?? '',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              (timeline[i] as Map<String, dynamic>)['activity']?.toString() ?? '',
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
