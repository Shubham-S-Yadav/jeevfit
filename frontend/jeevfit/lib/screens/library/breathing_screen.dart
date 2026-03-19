import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  Map<String, dynamic>? _pranayamaData;
  Map<String, dynamic>? _yogaData;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getPranayama(),
        _api.getYoga(goal: 'meditation'),
      ]);
      _pranayamaData = results[0];
      _yogaData = results[1];
    } catch (e) {
      _error = 'Failed to load data. Please try again.';
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
      appBar: AppBar(
        title: const Text('Breathing & Meditation'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.sleep,
          indicatorColor: AppColors.sleep,
          tabs: const [
            Tab(text: 'Pranayama', icon: Icon(Icons.air, size: 18)),
            Tab(text: 'Meditation', icon: Icon(Icons.self_improvement, size: 18)),
          ],
        ),
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
                        const Icon(Icons.air, size: 64, color: AppColors.textSecondary),
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPranayamaTab(),
                    _buildMeditationTab(),
                  ],
                ),
    );
  }

  Widget _buildPranayamaTab() {
    final techniques = (_pranayamaData?['techniques'] as List?) ?? [];
    if (techniques.isEmpty) {
      return const Center(
        child: Text('No pranayama techniques available.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: techniques.length,
        itemBuilder: (context, index) {
          final tech = techniques[index] as Map<String, dynamic>;
          return _buildPranayamaCard(tech);
        },
      ),
    );
  }

  Widget _buildPranayamaCard(Map<String, dynamic> tech) {
    final name = tech['name'] as String? ?? '';
    final difficulty = tech['difficulty'] as String? ?? 'beginner';
    final duration = tech['duration'] as String? ?? '';
    final steps = (tech['steps'] as List?)?.cast<String>() ?? [];
    final benefits = (tech['benefits'] as List?)?.cast<String>() ?? [];
    final cautions = (tech['cautions'] as List?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name, difficulty badge, duration
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sleep.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.air, color: AppColors.sleep, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
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
                          if (duration.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Steps
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Steps', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              for (int i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.sleep.withOpacity(0.1),
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sleep)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(steps[i], style: const TextStyle(fontSize: 13, height: 1.4))),
                    ],
                  ),
                ),
            ],

            // Benefits chips
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: benefits.map((b) => Chip(
                  label: Text(b, style: const TextStyle(fontSize: 10, color: AppColors.success)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.success.withOpacity(0.08),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],

            // Cautions
            if (cautions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text('Cautions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final c in cautions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('• $c', style: TextStyle(fontSize: 12, color: AppColors.warning.withOpacity(0.9))),
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

  Widget _buildMeditationTab() {
    final meditations = (_yogaData?['meditations'] as List?) ?? [];

    // Fallback if API returns no meditation data - show static content
    final meditationTypes = meditations.isNotEmpty
        ? meditations
        : [
            {
              'name': 'Mindfulness Meditation',
              'description': 'Focus on breath and present moment awareness. Start with 5 minutes and build up to 20.',
              'levels': {
                'beginner': '5 min daily - Focus on breath counting',
                'intermediate': '15 min daily - Body scan + breath awareness',
                'advanced': '20-30 min daily - Open awareness meditation',
              },
            },
            {
              'name': 'Vipassana',
              'description': 'Ancient Indian technique of observing bodily sensations without reaction.',
              'levels': {
                'beginner': '10 min - Anapana (breath at nostrils)',
                'intermediate': '30 min - Body sweep technique',
                'advanced': '1 hour sits, 10-day retreats',
              },
            },
            {
              'name': 'Yoga Nidra',
              'description': 'Guided sleep-based meditation for deep relaxation and recovery.',
              'levels': {
                'beginner': '15 min guided session before sleep',
                'intermediate': '30 min with sankalpa (intention setting)',
                'advanced': '45 min with rotation of consciousness',
              },
            },
            {
              'name': 'Transcendental Meditation',
              'description': 'Mantra-based silent meditation practiced for 20 minutes twice daily.',
              'levels': {
                'beginner': '10 min with simple mantra (Om)',
                'intermediate': '20 min twice daily with personal mantra',
                'advanced': '20 min twice daily + weekend group sessions',
              },
            },
          ];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: meditationTypes.length,
        itemBuilder: (context, index) {
          final med = meditationTypes[index] as Map<String, dynamic>;
          return _buildMeditationCard(med);
        },
      ),
    );
  }

  Widget _buildMeditationCard(Map<String, dynamic> med) {
    final name = med['name'] as String? ?? '';
    final description = med['description'] as String? ?? '';
    final levels = med['levels'] as Map<String, dynamic>? ?? {};

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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.stress.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.self_improvement, color: AppColors.stress, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (levels.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final entry in levels.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _difficultyColor(entry.key).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.key[0].toUpperCase() + entry.key.substring(1),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _difficultyColor(entry.key)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.value.toString(), style: const TextStyle(fontSize: 13, height: 1.4))),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
