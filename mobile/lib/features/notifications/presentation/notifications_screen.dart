import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            const Text(
              'Security & Network Alerts',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildNotificationItem(
              title: 'Mesh Relay Active',
              description: 'Your device successfully relayed an encrypted mesh ping for peer node.',
              time: '12 min ago',
              icon: Icons.bluetooth_audio_rounded,
              iconColor: AppColors.cyan,
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              title: 'Trusted Contact Confirmed',
              description: 'Aarav Sharma accepted your emergency contact authorization request.',
              time: 'Yesterday',
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.successGreen,
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              title: 'Safe Walk Completed',
              description: 'Your Safe Walk to Home, Sector 62 ended safely. Live coordinates purged.',
              time: '2 days ago',
              icon: Icons.directions_walk_rounded,
              iconColor: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(time, style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
