import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/emergency_permission_service.dart';
import '../../../../core/theme/app_colors.dart';

class EmergencyPermissionPrimerSheet extends ConsumerWidget {
  final VoidCallback? onCompleted;

  const EmergencyPermissionPrimerSheet({super.key, this.onCompleted});

  static Future<void> show(BuildContext context, {VoidCallback? onCompleted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmergencyPermissionPrimerSheet(onCompleted: onCompleted),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permState = ref.watch(emergencyPermissionsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.cyan, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Shield Setup',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${permState.grantedCount} of 6 Hardware Permissions Active',
                      style: TextStyle(
                        color: permState.allGranted ? AppColors.successGreen : AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Text(
            'GuardVarX works 100% offline without cellular data or internet. To enable P2P video call, walkie-talkie audio, and peer radar, activate these permissions:',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Permission Items
          _buildPermItem(
            icon: Icons.videocam_rounded,
            title: 'Camera Access',
            purpose: 'Offline P2P Video Call & Emergency Photo Evidence',
            isGranted: permState.camera,
          ),
          _buildPermItem(
            icon: Icons.mic_rounded,
            title: 'Microphone',
            purpose: 'Offline Walkie-Talkie Voice Calls & Audio Distress Beacon',
            isGranted: permState.microphone,
          ),
          _buildPermItem(
            icon: Icons.wifi_tethering_rounded,
            title: 'Nearby Wi-Fi Devices',
            purpose: 'Direct Phone-to-Phone High Speed Link (No Router Needed)',
            isGranted: permState.nearbyWifi,
          ),
          _buildPermItem(
            icon: Icons.bluetooth_rounded,
            title: 'Bluetooth Low Energy',
            purpose: 'Instant Peer Radar & Multi-hop Mesh Emergency Routing',
            isGranted: permState.bluetooth,
          ),
          _buildPermItem(
            icon: Icons.location_on_rounded,
            title: 'Location (GPS)',
            purpose: 'Encrypted Coordinates for Nearby Volunteers & Police 112',
            isGranted: permState.location,
          ),
          _buildPermItem(
            icon: Icons.notifications_active_rounded,
            title: 'Emergency Alerts',
            purpose: 'Full-screen incoming offline distress calls & SOS rings',
            isGranted: permState.notification,
          ),

          const SizedBox(height: 18),

          // Grant All Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: Icon(
                permState.allGranted ? Icons.check_circle_rounded : Icons.flash_on_rounded,
                color: Colors.white,
              ),
              label: Text(
                permState.allGranted ? 'All Permissions Active' : 'Grant All Emergency Permissions',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: permState.allGranted ? AppColors.successGreen : AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                if (permState.allGranted) {
                  Navigator.pop(context);
                  onCompleted?.call();
                  return;
                }
                final granted = await ref
                    .read(emergencyPermissionsProvider.notifier)
                    .requestAllEmergencyPermissions();
                if (granted) {
                  HapticFeedback.heavyImpact();
                  if (context.mounted) {
                    Navigator.pop(context);
                    onCompleted?.call();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermItem({
    required IconData icon,
    required String title,
    required String purpose,
    required bool isGranted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? AppColors.successGreen.withOpacity(0.3) : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isGranted ? AppColors.successGreen : AppColors.cyan,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  purpose,
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isGranted ? AppColors.successGreen : AppColors.warningAmber).withOpacity(0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isGranted ? 'ACTIVE' : 'GRANT',
              style: TextStyle(
                color: isGranted ? AppColors.successGreen : AppColors.warningAmber,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
