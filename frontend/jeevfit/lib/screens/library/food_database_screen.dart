import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class FoodDatabaseScreen extends ConsumerStatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  ConsumerState<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends ConsumerState<FoodDatabaseScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  Timer? _debounce;

  // Must match backend category keys from indian_nutrition_knowledge_base.json
  final _categories = {
    'Cereals & Millets': 'cereals_and_millets',
    'Pulses': 'pulses_and_legumes',
    'Vegetables': 'vegetables',
    'Fruits': 'fruits',
    'Dairy': 'dairy',
    'Oils & Fats': 'oils_and_fats',
    'Nuts & Seeds': 'nuts_and_seeds',
    'Spices': 'spices_and_herbs',
    'Prepared Foods': 'common_prepared_foods',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _data = await _api.getFoods(
        category: _selectedCategory != null ? _categories[_selectedCategory] : null,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    } catch (e) {
      _error = 'Failed to load foods. Please try again.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadData();
    });
  }

  Color _giColor(dynamic giValue) {
    if (giValue == null) return AppColors.textSecondary;
    final gi = (giValue is num) ? giValue.toDouble() : double.tryParse(giValue.toString()) ?? 0;
    if (gi < 55) return AppColors.success;
    if (gi < 70) return AppColors.warning;
    return AppColors.error;
  }

  String _giLabel(dynamic giValue) {
    if (giValue == null) return 'N/A';
    final gi = (giValue is num) ? giValue.toDouble() : double.tryParse(giValue.toString()) ?? 0;
    if (gi < 55) return 'Low GI';
    if (gi < 70) return 'Med GI';
    return 'High GI';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Database')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search foods (e.g. paneer, dal, chawal)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category filter chips
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() => _selectedCategory = null);
                    _loadData();
                  },
                  selectedColor: AppColors.diet.withOpacity(0.15),
                  checkmarkColor: AppColors.diet,
                ),
                const SizedBox(width: 8),
                for (final cat in _categories.keys) ...[
                  FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) {
                      setState(() => _selectedCategory = _selectedCategory == cat ? null : cat);
                      _loadData();
                    },
                    selectedColor: AppColors.diet.withOpacity(0.15),
                    checkmarkColor: AppColors.diet,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Food list
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
                              const Icon(Icons.restaurant_menu, size: 64, color: AppColors.textSecondary),
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
                    : _buildFoodList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    final foods = (_data?['foods'] as List?) ?? [];
    if (foods.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No foods found.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index] as Map<String, dynamic>;
          return _buildFoodCard(food);
        },
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    final name = food['name'] as String? ?? '';
    final hindiName = food['hindi_name'] as String? ?? '';
    final calories = food['calories'] ?? food['energy_kcal'] ?? 0;
    final protein = food['protein'] ?? food['protein_g'] ?? 0;
    final carbs = food['carbs'] ?? food['carbs_g'] ?? 0;
    final fat = food['fat'] ?? food['fat_g'] ?? 0;
    final gi = food['gi'] ?? food['glycemic_index'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.diet.withOpacity(0.1),
          child: const Icon(Icons.restaurant, color: AppColors.diet, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (hindiName.isNotEmpty)
                    Text(hindiName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            if (gi != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _giColor(gi).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _giLabel(gi),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _giColor(gi)),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _MacroBadge(label: 'Cal', value: '$calories', color: AppColors.secondary),
              const SizedBox(width: 8),
              _MacroBadge(label: 'P', value: '${_formatNum(protein)}g', color: AppColors.error),
              const SizedBox(width: 8),
              _MacroBadge(label: 'C', value: '${_formatNum(carbs)}g', color: AppColors.info),
              const SizedBox(width: 8),
              _MacroBadge(label: 'F', value: '${_formatNum(fat)}g', color: AppColors.warning),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 4),
                const Text('Nutritional Details (per 100g)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                _buildNutrientRow('Fiber', food['fiber'] ?? food['fiber_g']),
                _buildNutrientRow('Iron', food['iron'] ?? food['iron_mg'], unit: 'mg'),
                _buildNutrientRow('Calcium', food['calcium'] ?? food['calcium_mg'], unit: 'mg'),
                _buildNutrientRow('Zinc', food['zinc'] ?? food['zinc_mg'], unit: 'mg'),
                if (gi != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Glycemic Index: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _giColor(gi).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$gi (${_giLabel(gi)})',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _giColor(gi)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (food['key_nutrients'] != null) ...[
                  const SizedBox(height: 8),
                  const Text('Key Nutrients', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final n in _parseNutrients(food['key_nutrients']))
                        Chip(
                          label: Text(n, style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.diet.withOpacity(0.08),
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

  Widget _buildNutrientRow(String label, dynamic value, {String unit = 'g'}) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Text('${_formatNum(value)} $unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<String> _parseNutrients(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return [val.toString()];
  }

  String _formatNum(dynamic val) {
    if (val == null) return '0';
    if (val is num) {
      return val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);
    }
    return val.toString();
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
