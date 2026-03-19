import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SupplementGuideScreen extends ConsumerStatefulWidget {
  const SupplementGuideScreen({super.key});

  @override
  ConsumerState<SupplementGuideScreen> createState() => _SupplementGuideScreenState();
}

class _SupplementGuideScreenState extends ConsumerState<SupplementGuideScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  String _selectedTier = 'All';

  final _tiers = ['All', 'Essential', 'Goal-Based', 'Specific'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _data = await _api.getSupplements();
    } catch (e) {
      _error = 'Failed to load supplements. Please try again.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _tierColor(dynamic tier) {
    final t = tier?.toString().toLowerCase() ?? '';
    if (t == '1' || t == 'essential') return AppColors.primary;
    if (t == '2' || t == 'goal-based') return AppColors.secondary;
    if (t == '3' || t == 'specific') return AppColors.accent;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplement Guide')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.medication, size: 64, color: AppColors.textSecondary),
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tier filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              for (final tier in _tiers) ...[
                FilterChip(
                  label: Text(tier),
                  selected: _selectedTier == tier,
                  onSelected: (_) => setState(() => _selectedTier = tier),
                  selectedColor: _tierColor(tier == 'All' ? 'essential' : tier).withOpacity(0.15),
                  checkmarkColor: _tierColor(tier == 'All' ? 'essential' : tier),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),

        // Supplements list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _buildSupplementList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementList() {
    final supplements = (_data?['supplements'] as List?) ?? [];
    final filtered = _selectedTier == 'All'
        ? supplements
        : supplements.where((s) {
            final tier = (s as Map<String, dynamic>)['tier'];
            final tierStr = tier is int ? 'Tier $tier' : tier.toString();
            if (_selectedTier == 'Essential') return tier == 1;
            if (_selectedTier == 'Goal-Based') return tier == 2;
            if (_selectedTier == 'Specific') return tier == 3;
            return tierStr.toLowerCase().contains(_selectedTier.toLowerCase());
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No supplements found.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final supp = filtered[index] as Map<String, dynamic>;
        return _buildSupplementCard(supp);
      },
    );
  }

  Widget _buildSupplementCard(Map<String, dynamic> supp) {
    final tier = supp['tier']?.toString() ?? '';
    final name = supp['name']?.toString() ?? '';
    final description = supp['why_needed']?.toString() ?? supp['description']?.toString() ?? '';
    final dosage = supp['dosage'] is Map ? Map<String, dynamic>.from(supp['dosage']) : <String, dynamic>{};
    final whenToTake = supp['when_to_take']?.toString() ?? '';
    final forms = (supp['forms'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final contraindications = (supp['contraindications'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final brands = (supp['brands_india'] ?? supp['indian_brands'] as List?) ?? [];
    final references = (supp['research'] ?? supp['references'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _tierColor(tier).withOpacity(0.1),
          child: Icon(Icons.medication, color: _tierColor(tier), size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _tierColor(tier).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tier,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _tierColor(tier)),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),

                // Dosage table
                if (dosage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Dosage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        for (final entry in dosage.entries)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    entry.key[0].toUpperCase() + entry.key.substring(1),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(child: Text(entry.value.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // When to take
                if (whenToTake.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('When: $whenToTake', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],

                // Forms
                if (forms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Available Forms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: forms.map((f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],

                // Contraindications
                if (contraindications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber, size: 16, color: AppColors.error),
                            SizedBox(width: 6),
                            Text('Contraindications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final c in contraindications)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.error, fontSize: 12)),
                                Expanded(child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.error))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Indian brands with prices
                if (brands.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Indian Brands', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  for (final brand in brands)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront, size: 14, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(brand['name']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                          if (brand['price'] != null)
                            Text('₹${brand['price']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                ],

                // References
                if (references.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('References', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  for (final r in references)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $r', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
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
