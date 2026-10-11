import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../providers/community_provider.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  void _showNewReportDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'POOR_LIGHTING';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.primarySurface,
          title: const Text('Post Safety Warning', style: TextStyle(color: AppColors.primaryText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your exact location will be fuzzed to 500m to preserve your privacy.',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: AppColors.primarySurface,
                  style: const TextStyle(color: AppColors.primaryText),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: AppColors.secondaryText),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'POOR_LIGHTING', child: Text('Poor / No Lighting')),
                    DropdownMenuItem(value: 'HARASSMENT_HOTSPOT', child: Text('Unsafe Area / Loitering')),
                    DropdownMenuItem(value: 'ROAD_BLOCKAGE', child: Text('Road Hazard / Blockage')),
                    DropdownMenuItem(value: 'MISSING_PERSON', child: Text('Missing Person')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other Hazard')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.primaryText),
                  decoration: InputDecoration(
                    labelText: 'Summary Title',
                    labelStyle: const TextStyle(color: AppColors.secondaryText),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.primaryText),
                  decoration: InputDecoration(
                    labelText: 'Detailed Description',
                    labelStyle: const TextStyle(color: AppColors.secondaryText),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty && descController.text.trim().isNotEmpty) {
                  ref.read(communityProvider.notifier).addReport(
                        category,
                        titleController.text.trim(),
                        descController.text.trim(),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Post Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(communityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Safety'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: AppColors.cyan),
            onPressed: _showNewReportDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            const Text(
              'Local Safety Advisories',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Verified reports from community members across your sector. Exact coordinates are rounded to 500m to prevent targeting individuals.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),

            ...reports.map((rep) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rep.category.replaceAll('_', ' '),
                              style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 4),
                              Text('${rep.upvotes}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rep.title,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rep.description,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Near: ${rep.latitudeFuzzed.toStringAsFixed(2)}, ${rep.longitudeFuzzed.toStringAsFixed(2)} (~500m radius)',
                            style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
                          ),
                          const Text(
                            'Active warning',
                            style: TextStyle(color: AppColors.warningAmber, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
