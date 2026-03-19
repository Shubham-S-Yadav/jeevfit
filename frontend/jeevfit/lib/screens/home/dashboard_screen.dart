import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _assessment;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _dashboard = await _api.getDashboard();
    } catch (_) {}
    try {
      _assessment = await _api.getLatestAssessment();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _generateAllPlans() async {
    setState(() => _isGenerating = true);
    ApiService.isGeneratingDiet = true;
    ApiService.isGeneratingExercise = true;
    ApiService.isGeneratingTimetable = true;

    final results = await Future.wait([
      _api.generateDietPlan().then((_) { ApiService.isGeneratingDiet = false; return 'Diet plan'; }).catchError((e) { ApiService.isGeneratingDiet = false; return 'Diet: failed'; }),
      _api.generateExercisePlan().then((_) { ApiService.isGeneratingExercise = false; return 'Exercise plan'; }).catchError((e) { ApiService.isGeneratingExercise = false; return 'Exercise: failed'; }),
      _api.generateTimetable().then((_) { ApiService.isGeneratingTimetable = false; return 'Timetable'; }).catchError((e) { ApiService.isGeneratingTimetable = false; return 'Timetable: failed'; }),
    ]);

    if (mounted) {
      final succeeded = results.where((r) => !r.toString().contains('failed')).length;
      final failed = 3 - succeeded;
      if (failed == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All plans generated! Check Diet, Exercise, and Schedule tabs.'), backgroundColor: AppColors.success),
        );
      } else if (succeeded > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$succeeded/3 plans generated. $failed failed — try again.'), backgroundColor: AppColors.warning),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan generation failed. Please try again.'), backgroundColor: AppColors.error),
        );
      }
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JeevFit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => context.push('/assessment'),
            tooltip: 'Health Assessment',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let's make today count!",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Health Score Card
                    if (_assessment != null) _buildHealthScoreCard(),

                    // Generate Plans CTA
                    const SizedBox(height: 16),
                    _buildGeneratePlansCard(),

                    // Quick Stats
                    if (_dashboard != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('This Week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          TextButton(
                            onPressed: () => context.push('/tracking'),
                            child: const Text('View History', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatsGrid(),
                    ],

                    // Quick Actions
                    const SizedBox(height: 20),
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildQuickActions(),

                    // Explore Library section
                    const SizedBox(height: 20),
                    const Text('Explore Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildExploreSection(),

                    const SizedBox(height: 20),
                    // Tips Card
                    _buildTipCard(),
                  ],
                ),
              ),
            ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  Widget _buildHealthScoreCard() {
    final score = _assessment?['overall_score'] ?? 0;
    final summary = _assessment?['ai_summary'] ?? 'Upload a photo to get your health assessment.';
    Color scoreColor;
    if (score >= 70) {
      scoreColor = AppColors.success;
    } else if (score >= 50) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${score.toInt()}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scoreColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Health Score', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(summary, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratePlansCard() {
    return Card(
      color: AppColors.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isGenerating ? null : _generateAllPlans,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate AI Plans',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isGenerating ? 'Creating your personalized plans...' : 'Diet + Exercise + Timetable - all personalized for you',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_isGenerating)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.local_fire_department,
          label: 'Avg Calories',
          value: _dashboard?['avg_calories']?.toStringAsFixed(0) ?? '--',
          color: AppColors.secondary,
        ),
        _StatCard(
          icon: Icons.bedtime,
          label: 'Avg Sleep',
          value: _dashboard?['avg_sleep'] != null ? '${_dashboard!['avg_sleep'].toStringAsFixed(1)}h' : '--',
          color: AppColors.sleep,
        ),
        _StatCard(
          icon: Icons.favorite,
          label: 'Avg Stress',
          value: _dashboard?['avg_stress']?.toStringAsFixed(1) ?? '--',
          color: AppColors.stress,
        ),
        _StatCard(
          icon: Icons.monitor_weight,
          label: 'Weight Change',
          value: _dashboard?['weight_change'] != null ? '${_dashboard!['weight_change'] > 0 ? '+' : ''}${_dashboard!['weight_change'].toStringAsFixed(1)} kg' : '--',
          color: AppColors.diet,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.restaurant,
            label: 'Log Meal',
            color: AppColors.diet,
            onTap: () => context.push('/log/meal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.fitness_center,
            label: 'Log Workout',
            color: AppColors.exercise,
            onTap: () => context.push('/log/exercise'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.checklist,
            label: 'Check-in',
            color: AppColors.accent,
            onTap: () => context.push('/log/progress'),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ExploreCard(icon: Icons.fitness_center, label: 'Exercises', color: AppColors.exercise, onTap: () => context.push('/library/exercises')),
          const SizedBox(width: 10),
          _ExploreCard(icon: Icons.medication, label: 'Supplements', color: AppColors.primary, onTap: () => context.push('/library/supplements')),
          const SizedBox(width: 10),
          _ExploreCard(icon: Icons.restaurant_menu, label: 'Foods', color: AppColors.diet, onTap: () => context.push('/library/foods')),
          const SizedBox(width: 10),
          _ExploreCard(icon: Icons.air, label: 'Breathing', color: AppColors.sleep, onTap: () => context.push('/library/breathing')),
          const SizedBox(width: 10),
          _ExploreCard(icon: Icons.bedtime, label: 'Sleep Guide', color: AppColors.stress, onTap: () => context.push('/library/sleep')),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Card(
      color: AppColors.accent.withOpacity(0.05),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.accent),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Tip', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    'Drink warm water with lemon first thing in the morning. It kickstarts your metabolism and aids digestion.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ExploreCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
