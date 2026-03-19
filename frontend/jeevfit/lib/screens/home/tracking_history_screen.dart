import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TrackingHistoryScreen extends StatefulWidget {
  const TrackingHistoryScreen({super.key});

  @override
  State<TrackingHistoryScreen> createState() => _TrackingHistoryScreenState();
}

class _TrackingHistoryScreenState extends State<TrackingHistoryScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  List<dynamic> _todayMeals = [];
  List<dynamic> _progressHistory = [];
  bool _isLoadingMeals = true;
  bool _isLoadingProgress = true;

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
    _loadMeals();
    _loadProgress();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoadingMeals = true);
    try {
      _todayMeals = await _api.getTodayMeals();
    } catch (_) {
      _todayMeals = [];
    }
    if (mounted) setState(() => _isLoadingMeals = false);
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoadingProgress = true);
    try {
      _progressHistory = await _api.getProgressHistory(days: 14);
    } catch (_) {
      _progressHistory = [];
    }
    if (mounted) setState(() => _isLoadingProgress = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: "Today's Meals"),
            Tab(icon: Icon(Icons.timeline), text: 'Progress'),
          ],
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMealsTab(),
          _buildProgressTab(),
        ],
      ),
    );
  }

  Widget _buildMealsTab() {
    if (_isLoadingMeals) return const Center(child: CircularProgressIndicator());

    if (_todayMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No meals logged today', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap "Log Meal" on the dashboard to start', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final totalCals = _todayMeals.fold<int>(0, (sum, m) => sum + ((m['total_calories'] as int?) ?? 0));

    return RefreshIndicator(
      onRefresh: _loadMeals,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.diet.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('$totalCals', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.diet)),
                  const Text('Total Calories', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
                Column(children: [
                  Text('${_todayMeals.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.diet)),
                  const Text('Meals Logged', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          for (final meal in _todayMeals)
            _buildMealCard(meal is Map<String, dynamic> ? meal : Map<String, dynamic>.from(meal as Map)),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final mealType = (meal['meal_type'] ?? '').toString().replaceAll('_', ' ');
    final items = (meal['items'] as List?) ?? [];
    final totalCal = meal['total_calories'] ?? 0;
    final followedPlan = meal['followed_plan'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, size: 18, color: AppColors.diet),
                const SizedBox(width: 8),
                Text(mealType[0].toUpperCase() + mealType.substring(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('$totalCal cal', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.diet)),
                if (followedPlan == true) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                ],
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '${item['name'] ?? ''} — ${item['qty'] ?? ''}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    )),
                    Text('${item['calories'] ?? 0} cal', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    if (_isLoadingProgress) return const Center(child: CircularProgressIndicator());

    if (_progressHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No progress logged yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap "Daily Check-in" on the dashboard', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _progressHistory.length,
        itemBuilder: (context, index) {
          final entry = _progressHistory[index] is Map<String, dynamic>
              ? _progressHistory[index]
              : Map<String, dynamic>.from(_progressHistory[index] as Map);
          return _buildProgressCard(entry);
        },
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> entry) {
    final entryDate = entry['entry_date']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(entryDate, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (entry['weight_kg'] != null) _metric('Weight', '${entry['weight_kg']} kg', Icons.monitor_weight, AppColors.primary),
                if (entry['sleep_hours'] != null) _metric('Sleep', '${entry['sleep_hours']}h', Icons.bedtime, AppColors.sleep),
                if (entry['sleep_quality'] != null) _metric('Sleep Q', '${entry['sleep_quality']}/10', Icons.star, AppColors.sleep),
                if (entry['stress_level'] != null) _metric('Stress', '${entry['stress_level']}/10', Icons.psychology, AppColors.stress),
                if (entry['energy_level'] != null) _metric('Energy', '${entry['energy_level']}/10', Icons.bolt, AppColors.secondary),
                if (entry['mood'] != null) _metric('Mood', '${entry['mood']}/10', Icons.mood, AppColors.accent),
                if (entry['water_liters'] != null) _metric('Water', '${entry['water_liters']}L', Icons.water_drop, AppColors.info),
                if (entry['skin_rating'] != null) _metric('Skin', '${entry['skin_rating']}/10', Icons.face, AppColors.skin),
                if (entry['hair_rating'] != null) _metric('Hair', '${entry['hair_rating']}/10', Icons.content_cut, AppColors.hair),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 90,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
