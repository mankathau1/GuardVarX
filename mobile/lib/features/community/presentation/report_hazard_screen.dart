import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../providers/community_provider.dart';

class ReportHazardScreen extends ConsumerStatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  ConsumerState<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends ConsumerState<ReportHazardScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'POOR_LIGHTING';
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    await ref.read(communityProvider.notifier).addReport(
          _category,
          _titleController.text.trim(),
          _descController.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Report Hazard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help Make Your Area Safer',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Submitting a hazard informs community members in your sector. Exact coordinates are rounded to 500m to preserve your privacy.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hazard Category', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'POOR_LIGHTING', child: Text('Dark Stretch / Broken Lights')),
                        DropdownMenuItem(value: 'HARASSMENT_HOTSPOT', child: Text('Unsafe Loitering / Harassment')),
                        DropdownMenuItem(value: 'ROAD_BLOCKAGE', child: Text('Road Crash / Flooded Underpass')),
                        DropdownMenuItem(value: 'MISSING_PERSON', child: Text('Missing Person')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other Hazard')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Title Summary', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'e.g. Unlit walkway near Metro Gate 3',
                        hintStyle: const TextStyle(color: AppColors.mutedText),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Detailed Observation', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Provide landmark details and timings so peers can avoid the risk...',
                        hintStyle: const TextStyle(color: AppColors.mutedText),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Post Community Advisory', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
