import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

class EmergencyHistoryScreen extends StatelessWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Emergency History')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            const Text(
              'Audit Log & Past Incidents',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Per privacy and data retention policy, raw GPS coordinates are pruned 24 hours after resolution.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            _buildHistoryItem(
              type: 'Personal Safety Threat',
              timestamp: 'Oct 08, 2026 • 21:45 IST',
              status: 'Resolved safely',
              statusColor: AppColors.successGreen,
              receiptId: 'rcpt_89a0b12',
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              type: 'Vehicle Breakdown',
              timestamp: 'Sep 24, 2026 • 19:12 IST',
              status: 'Cancelled by user',
              statusColor: AppColors.secondaryText,
              receiptId: 'rcpt_33f1c98',
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              type: 'Medical Emergency Alert',
              timestamp: 'Aug 15, 2026 • 14:03 IST',
              status: 'Resolved safely',
              statusColor: AppColors.successGreen,
              receiptId: 'rcpt_11d2e45',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String type,
    required String timestamp,
    required String status,
    required Color statusColor,
    required String receiptId,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(timestamp, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            'Cryptographic Receipt: $receiptId',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
