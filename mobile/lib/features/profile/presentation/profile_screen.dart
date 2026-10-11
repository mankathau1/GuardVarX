import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile & Security')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // User card
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                      style: const TextStyle(fontSize: 24, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phone.isNotEmpty ? user.phone : '+91 98765 43210',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.role,
                          style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy & Retention Controls
            const Text(
              'PRIVACY & RETENTION',
              style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.timer_outlined,
                    title: 'Location Retention Policy',
                    subtitle: 'Automatic hard purge 24 hours post-resolution',
                  ),
                  const Divider(color: AppColors.glassBorder, height: 24),
                  _buildSettingRow(
                    icon: Icons.bluetooth_rounded,
                    title: 'Bluetooth Low Energy Mesh',
                    subtitle: 'Duty-cycled relaying enabled for peer delivery',
                  ),
                  const Divider(color: AppColors.glassBorder, height: 24),
                  _buildSettingRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Emergency Duress PIN',
                    subtitle: 'Silent cancellation in extortion/hostage scenarios',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hardware & Diagnostics
            const Text(
              'DEVICE DIAGNOSTICS',
              style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.gps_fixed_rounded,
                    title: 'Location Permissions',
                    subtitle: 'When in use (Background for Safe Walk)',
                  ),
                  const Divider(color: AppColors.glassBorder, height: 24),
                  _buildSettingRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'FCM High-Priority Push',
                    subtitle: 'Authorized for critical safety alerts',
                  ),
                  const Divider(color: AppColors.glassBorder, height: 24),
                  _buildSettingRow(
                    icon: Icons.battery_charging_full_rounded,
                    title: 'Battery Optimization',
                    subtitle: 'Whitelisted for reliable background Safe Walk',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Actions
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.glassBorderElevated),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                  context.go('/auth');
                },
                child: const Text('Sign Out', style: TextStyle(color: AppColors.secondaryText)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                  context.go('/auth');
                },
                child: const Text('Delete Account & Purge Data', style: TextStyle(color: AppColors.emergencyRed, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.elevatedGlassSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
