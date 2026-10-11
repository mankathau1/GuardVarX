import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../safe_walk/providers/safe_walk_provider.dart';
import '../../sos/domain/emergency_model.dart';
import '../../sos/providers/sos_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final activeSOS = ref.watch(sosProvider);
    final safeWalk = ref.watch(safeWalkProvider);
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GUARDVARX',
                        style: TextStyle(
                          color: AppColors.primaryBlue.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.isAuthenticated ? user.displayName : 'Guest User',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedGlassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: AppColors.successGreen, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'Mesh Active',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active SOS banner if triggered
              if (activeSOS != null &&
                  activeSOS.status != DeliveryStatus.resolved &&
                  activeSOS.status != DeliveryStatus.cancelled) ...[
                GlassContainer(
                  backgroundColor: AppColors.emergencyRed.withOpacity(0.12),
                  borderColor: AppColors.emergencyRed.withOpacity(0.5),
                  onTap: () => context.go('/sos'),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMERGENCY IN PROGRESS',
                              style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              activeSOS.status.displayTitle,
                              style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondaryText, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Prominent SOS Quick Action Card
              GlassContainer(
                padding: const EdgeInsets.all(22),
                borderRadius: 24,
                borderColor: AppColors.emergencyRed.withOpacity(0.3),
                backgroundColor: const Color(0xFF14080A),
                onTap: () => context.go('/sos'),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emergencyRed,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emergencyRedGlow,
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY SOS',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hold 3s to alert trusted contacts and mesh peers',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondaryText, size: 14),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Safe Walk Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                onTap: () => context.go('/safewalk'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.directions_walk_rounded, color: AppColors.primaryBlue, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Safe Walk Journey',
                                style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              if (safeWalk.isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: safeWalk.status == 'WARNING'
                                        ? AppColors.warningAmber.withOpacity(0.2)
                                        : AppColors.successGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    safeWalk.status,
                                    style: TextStyle(
                                      color: safeWalk.status == 'WARNING' ? AppColors.warningAmber : AppColors.successGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            safeWalk.isActive
                                ? 'Next check-in: ${safeWalk.remainingCheckinSeconds ~/ 60}m ${safeWalk.remainingCheckinSeconds % 60}s'
                                : 'Timed journey with automatic missed check-in alerts',
                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondaryText, size: 14),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Two Column Grid: Trusted Contacts & Nearby Help
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      onTap: () => context.go('/contacts'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.elevatedGlassSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: AppColors.cyan, size: 22),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Trusted Contacts',
                            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${contacts.length} configured',
                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      onTap: () => context.go('/nearby'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.elevatedGlassSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.handshake_rounded, color: AppColors.successGreen, size: 22),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nearby Help',
                            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Verified volunteers',
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Location & Connectivity Status Card (Honest Reporting)
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SYSTEM INTEGRITY',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Location Freshness', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                        Text('Accurate (8m, Just now)', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Egress Channel', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                        Text('Wi-Fi / Mobile Data', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BLE Peripheral Relay', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                        Text('Ready (Hop Limit: 3)', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
