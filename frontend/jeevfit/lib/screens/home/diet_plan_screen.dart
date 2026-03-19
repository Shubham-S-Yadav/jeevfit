import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> with SingleTickerProviderStateMixin {
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
    // Default to current day
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
    if (ApiService.isGeneratingDiet) {
      setState(() { _isLoading = true; _error = null; });
      // Poll until generation is done
      while (ApiService.isGeneratingDiet) {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
      }
      // Generation finished, try loading
      try {
        _plan = await _api.getActiveDietPlan();
      } catch (e) {
        _error = 'Plan generation may have failed. Try again from Dashboard.';
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      _plan = await _api.getActiveDietPlan();
    } catch (e) {
      _error = 'No active diet plan. Generate one from the Dashboard!';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _regenerate() async {
    setState(() { _isLoading = true; _error = null; });
    ApiService.isGeneratingDiet = true;
    try {
      _plan = await _api.generateDietPlan();
    } catch (e) {
      _error = 'Failed to generate: ${e.toString()}';
    }
    ApiService.isGeneratingDiet = false;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan'),
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
                Text('Creating your personalized diet plan...', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _regenerate,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Diet Plan'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPlanView(),
    );
  }

  Widget _buildPlanView() {
    final mealPlan = _plan!['meal_plan'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Macro summary
        _buildMacroSummary(),

        // Day tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _dayLabels.map((d) => Tab(text: d)).toList(),
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
        ),

        // Meals for selected day
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _days.map((day) {
              final dayPlan = mealPlan[day] as Map<String, dynamic>? ?? {};
              return _buildDayMeals(day, dayPlan);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MacroPill(label: 'Calories', value: '${_plan!['daily_calories']}', unit: 'kcal', color: AppColors.secondary),
          _MacroPill(label: 'Protein', value: '${_plan!['protein_g']}', unit: 'g', color: AppColors.error),
          _MacroPill(label: 'Carbs', value: '${_plan!['carbs_g']}', unit: 'g', color: AppColors.info),
          _MacroPill(label: 'Fat', value: '${_plan!['fat_g']}', unit: 'g', color: AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildDayMeals(String day, Map<String, dynamic> dayPlan) {
    final mealOrder = ['early_morning', 'breakfast', 'mid_morning_snack', 'lunch', 'evening_snack', 'dinner', 'before_bed'];
    final mealNames = {
      'early_morning': 'Early Morning',
      'breakfast': 'Breakfast',
      'mid_morning_snack': 'Mid-Morning Snack',
      'lunch': 'Lunch',
      'evening_snack': 'Evening Snack',
      'dinner': 'Dinner',
      'before_bed': 'Before Bed',
    };
    final mealIcons = {
      'early_morning': Icons.wb_twilight,
      'breakfast': Icons.breakfast_dining,
      'mid_morning_snack': Icons.apple,
      'lunch': Icons.lunch_dining,
      'evening_snack': Icons.coffee,
      'dinner': Icons.dinner_dining,
      'before_bed': Icons.nightlight,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final mealKey in mealOrder)
          if (dayPlan.containsKey(mealKey))
            _buildMealCard(
              day,
              mealKey,
              mealNames[mealKey] ?? mealKey,
              mealIcons[mealKey] ?? Icons.restaurant,
              dayPlan[mealKey] as Map<String, dynamic>,
            ),

        // Supplements section
        if (_plan!['supplements'] != null) ...[
          const SizedBox(height: 16),
          const Text('Supplements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final supp in (_plan!['supplements'] as List))
            Card(
              color: AppColors.accent.withOpacity(0.05),
              child: ListTile(
                leading: const Icon(Icons.medication, color: AppColors.accent),
                title: Text('${supp['name']} - ${supp['dosage']}'),
                subtitle: Text('${supp['when']}\n${supp['reason']}', style: const TextStyle(fontSize: 12)),
                isThreeLine: true,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildMealCard(String day, String mealKey, String title, IconData icon, Map<String, dynamic> meal) {
    final items = (meal['items'] as List?) ?? [];
    final time = meal['time'] ?? '';
    final totalCal = meal['total_calories'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            GestureDetector(
              onTap: () => _showAlternativeChat(day, mealKey, title, meal),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, size: 14, color: AppColors.accent),
                    SizedBox(width: 4),
                    Text('Swap', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        subtitle: Text('$time  |  $totalCal kcal', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        children: [
          for (final item in items)
            ListTile(
              dense: true,
              title: Text(item['name']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
              subtitle: item['benefit'] != null ? Text(item['benefit'].toString(), style: const TextStyle(fontSize: 11, color: AppColors.accent)) : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['qty']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('${item['calories'] ?? 0} kcal', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAlternativeChat(String day, String mealKey, String mealTitle, Map<String, dynamic> meal) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _MealAlternativeChat(
          day: day,
          mealKey: mealKey,
          mealTitle: mealTitle,
          meal: meal,
        ),
      ),
    );
  }
}

// ==================== MEAL ALTERNATIVE CHAT ====================

class _MealAlternativeChat extends StatefulWidget {
  final String day;
  final String mealKey;
  final String mealTitle;
  final Map<String, dynamic> meal;

  const _MealAlternativeChat({
    required this.day,
    required this.mealKey,
    required this.mealTitle,
    required this.meal,
  });

  @override
  State<_MealAlternativeChat> createState() => _MealAlternativeChatState();
}

class _MealAlternativeChatState extends State<_MealAlternativeChat> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = []; // {role, text, alternatives?}
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Build initial context message
    final items = (widget.meal['items'] as List?) ?? [];
    final itemsDesc = items.map((i) => '${i['name']} (${i['qty']})').join(', ');
    final totalCal = widget.meal['total_calories'] ?? 0;
    _messages.add({
      'role': 'system',
      'text': '${widget.day.substring(0, 1).toUpperCase()}${widget.day.substring(1)} ${widget.mealTitle}: $itemsDesc — $totalCal cal',
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // Build conversation for API (exclude system message)
      final conversation = _messages
          .where((m) => m['role'] != 'system')
          .map((m) => {'role': m['role'] as String, 'text': m['text'] as String})
          .toList();

      final result = await _api.getMealAlternative(
        mealContext: {
          'day': widget.day,
          'meal_type': widget.mealKey,
          'items': widget.meal['items'] ?? [],
          'total_calories': widget.meal['total_calories'] ?? 0,
        },
        conversation: conversation,
      );

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': result['message']?.toString() ?? 'Here are some alternatives:',
            'alternatives': result['alternatives'],
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'text': 'Sorry, I couldn\'t generate alternatives. Please try again.'});
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Meal Alternatives', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Quick suggestion chips
          if (_messages.length <= 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickChip(label: "I'm fasting today", onTap: () { _controller.text = "I'm fasting today, what can I eat?"; _send(); }),
                  _QuickChip(label: "I'm traveling", onTap: () { _controller.text = "I'm traveling and only have restaurant food available"; _send(); }),
                  _QuickChip(label: "Don't have ingredients", onTap: () { _controller.text = "I don't have the ingredients for this meal, suggest something simpler"; _send(); }),
                  _QuickChip(label: "Something lighter", onTap: () { _controller.text = "Can I have something lighter with fewer calories?"; _send(); }),
                  _QuickChip(label: "Quick & easy", onTap: () { _controller.text = "I'm short on time, what's a quick 5-minute alternative?"; _send(); }),
                ],
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 4, bottomPadding + 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Tell me your situation...",
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isLoading ? null : _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final role = msg['role'];
    final text = msg['text'] ?? '';
    final alternatives = msg['alternatives'] as List?;

    if (role == 'system') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
          ],
        ),
      );
    }

    if (role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(4)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      );
    }

    // Assistant message
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
            ),
            child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
          if (alternatives != null)
            for (final alt in alternatives)
              if (alt is Map)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(alt['name']?.toString() ?? 'Alternative', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.diet.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${alt['total_calories'] ?? '?'} cal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.diet)),
                          ),
                        ],
                      ),
                      if (alt['items'] is List) ...[
                        const SizedBox(height: 8),
                        for (final item in alt['items'])
                          if (item is Map)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(
                                    '${item['name'] ?? ''} (${item['qty'] ?? ''}) — ${item['calories'] ?? '?'} cal',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  )),
                                ],
                              ),
                            ),
                      ],
                      if (alt['why'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Expanded(child: Text(alt['why'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontStyle: FontStyle.italic))),
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
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        backgroundColor: AppColors.accent.withOpacity(0.08),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MacroPill({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
