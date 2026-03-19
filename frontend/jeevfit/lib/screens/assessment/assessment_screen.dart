import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  String? _imagePath;
  String _imageType = 'front';
  Map<String, dynamic>? _result;
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1080, maxHeight: 1920, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
        _result = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_imagePath == null) return;
    setState(() => _isAnalyzing = true);
    try {
      _result = await _api.analyzeImage(_imagePath!, _imageType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: AppColors.info.withOpacity(0.05),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info),
                        SizedBox(width: 8),
                        Text('How to take the best photo', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('1. Wear fitted clothing (t-shirt & shorts)\n'
                        '2. Stand in good lighting\n'
                        '3. Take a front-facing full body photo\n'
                        '4. Keep your arms slightly away from body\n'
                        '5. Stand naturally - don\'t flex',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image type selection
            const Text('Photo Type', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final type in [
                  {'value': 'front', 'label': 'Front View'},
                  {'value': 'side', 'label': 'Side View'},
                  {'value': 'back', 'label': 'Back View'},
                  {'value': 'face', 'label': 'Face/Selfie'},
                ])
                  ChoiceChip(
                    label: Text(type['label']!),
                    selected: _imageType == type['value'],
                    onSelected: (_) => setState(() => _imageType = type['value']!),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Image preview or picker
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_imagePath!),
                  height: 300,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('Upload or take a photo', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Pick image buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Analyze button
            if (_imagePath != null)
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyze,
                  icon: _isAnalyzing ? const SizedBox.shrink() : const Icon(Icons.auto_awesome),
                  label: _isAnalyzing
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Analyzing...'),
                          ],
                        )
                      : const Text('Analyze with AI'),
                ),
              ),
            const SizedBox(height: 24),

            // Results
            if (_result != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final score = (_result!['overall_score'] ?? 0).toDouble();
    final summary = _result!['ai_summary'] ?? '';
    Color scoreColor;
    if (score >= 70) {
      scoreColor = AppColors.success;
    } else if (score >= 50) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Assessment Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Score
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withOpacity(0.1),
                  border: Border.all(color: scoreColor, width: 3),
                ),
                child: Center(
                  child: Text('${score.toInt()}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: scoreColor)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Health Score', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(summary, style: const TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(height: 12),

        // Body type & fat
        if (_result!['body_type'] != null || _result!['estimated_body_fat_pct'] != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Body Composition', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Divider(),
                  if (_result!['body_type'] != null) _ResultRow('Body Type', _result!['body_type']),
                  if (_result!['estimated_body_fat_pct'] != null) _ResultRow('Est. Body Fat', '${_result!['estimated_body_fat_pct']}%'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Recommendations
        if (_result!['ai_recommendations'] != null) ...[
          const Text('Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final rec in (_result!['ai_recommendations'] as List))
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: AppColors.accent),
                title: Text(rec.toString(), style: const TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ],
    );
  }

  Widget _ResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
