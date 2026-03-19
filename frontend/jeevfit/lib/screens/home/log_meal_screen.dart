import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final _api = ApiService();
  bool _isSaving = false;

  String _mealType = 'breakfast';
  final List<Map<String, dynamic>> _items = [];
  bool _followedPlan = true;
  final _notesController = TextEditingController();

  // For adding items
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _calController = TextEditingController();

  final _mealTypes = [
    {'value': 'early_morning', 'label': 'Early Morning', 'icon': Icons.wb_twilight},
    {'value': 'breakfast', 'label': 'Breakfast', 'icon': Icons.free_breakfast},
    {'value': 'mid_morning_snack', 'label': 'Mid-Morning Snack', 'icon': Icons.apple},
    {'value': 'lunch', 'label': 'Lunch', 'icon': Icons.lunch_dining},
    {'value': 'evening_snack', 'label': 'Evening Snack', 'icon': Icons.cookie},
    {'value': 'dinner', 'label': 'Dinner', 'icon': Icons.dinner_dining},
    {'value': 'before_bed', 'label': 'Before Bed', 'icon': Icons.bedtime},
  ];

  void _addItem() {
    if (_nameController.text.isEmpty) return;
    setState(() {
      _items.add({
        'name': _nameController.text,
        'qty': _qtyController.text.isNotEmpty ? _qtyController.text : '1 serving',
        'calories': int.tryParse(_calController.text) ?? 0,
      });
      _nameController.clear();
      _qtyController.clear();
      _calController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one food item'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final totalCals = _items.fold<int>(0, (sum, item) => sum + ((item['calories'] as int?) ?? 0));
      await _api.logMeal({
        'meal_type': _mealType,
        'items': _items,
        'total_calories': totalCals,
        'followed_plan': _followedPlan,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal logged!'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop(true);
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
    _qtyController.dispose();
    _calController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
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
            // Meal type selector
            const Text('Meal Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _mealTypes.map((mt) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(mt['icon'] as IconData, size: 16),
                    label: Text(mt['label'] as String, style: const TextStyle(fontSize: 12)),
                    selected: _mealType == mt['value'],
                    onSelected: (_) => setState(() => _mealType = mt['value'] as String),
                    showCheckmark: false,
                    selectedColor: AppColors.diet.withOpacity(0.2),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Add food items
            const Text('Food Items', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Food name', isDense: true),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(hintText: 'Qty (e.g. 2 roti)', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _calController,
                    decoration: const InputDecoration(hintText: 'Cal', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle, color: AppColors.diet),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items list
            if (_items.isNotEmpty) ...[
              for (int i = 0; i < _items.length; i++)
                Card(
                  child: ListTile(
                    dense: true,
                    title: Text(_items[i]['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${_items[i]['qty']}  •  ${_items[i]['calories']} cal'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      onPressed: () => _removeItem(i),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Total: ${_items.fold<int>(0, (sum, item) => sum + ((item['calories'] as int?) ?? 0))} calories',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.diet),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No items added yet', style: TextStyle(color: AppColors.textSecondary))),
              ),

            const SizedBox(height: 20),

            // Followed plan toggle
            SwitchListTile(
              title: const Text('Followed diet plan?'),
              value: _followedPlan,
              onChanged: (v) => setState(() => _followedPlan = v),
              activeColor: AppColors.diet,
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
