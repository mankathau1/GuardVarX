import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/live_location_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../safe_walk/providers/safe_walk_provider.dart';
import '../../sos/domain/emergency_model.dart';
import '../../sos/providers/sos_provider.dart';
import '../../im_guard/providers/im_guard_provider.dart';
import '../../../core/services/emergency_permission_service.dart';
import '../../auth/presentation/widgets/emergency_permission_primer_dialog.dart';
import 'widgets/home_header.dart';
import 'widgets/safety_status_card.dart';
import 'widgets/location_card.dart';
import 'widgets/central_sos_section.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/safe_walk_session_card.dart';
import 'widgets/safety_tip_card.dart';
import 'widgets/dual_wing_floating_dock.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final activeSOS = ref.watch(sosProvider);
    final safeWalk = ref.watch(safeWalkProvider);
    final contacts = ref.watch(contactsProvider);
    final liveLoc = ref.watch(liveLocationProvider);
    final homeScrollCtrl = ref.watch(homeScrollControllerProvider);
    final emergencyPerms = ref.watch(emergencyPermissionsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: const DualWingFloatingDock(),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            controller: homeScrollCtrl,
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. Header
                HomeHeader(
                  userName: user.isAuthenticated ? user.displayName : 'Priya',
                  unreadNotificationsCount: 1,
                  onNotificationsTap: () => context.push('/notifications'),
                  onProfileTap: () => ref.read(mainNavigationProvider.notifier).setTab(4),
                ),
                const SizedBox(height: AppSpacing.md),

                // Emergency Hardware Shield Banner (If not all granted)
                if (!emergencyPerms.allGranted) ...[
                  InkWell(
                    onTap: () => EmergencyPermissionPrimerSheet.show(context),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cyan.withOpacity(0.18),
                            AppColors.primaryBlue.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: AppColors.cyan, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Activate Emergency Hardware Shield',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${emergencyPerms.grantedCount}/6 Active • Tap to enable offline video & walkie-talkie',
                                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cyan,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVATE',
                              style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // B. Safety & Connectivity Status Card
                SafetyStatusCard(
                  hasLocationPermission: liveLoc.hasPermission,
                  isNetworkConnected: true,
                  statusTitle: 'You are safe',
                  locationFreshnessText: liveLoc.isGpsLive
                      ? 'Live GPS • Accuracy ${liveLoc.accuracy.toStringAsFixed(0)} m'
                      : 'Location active • Accuracy 12 m',
                  networkTitle: 'Online',
                  lastUpdatedText: 'Last updated\n2 min ago',
                  onTap: () => context.push('/location-details'),
                ),
                const SizedBox(height: AppSpacing.md),

                // C. Current Location Card
                LocationCard(
                  address: liveLoc.address,
                  cityState: liveLoc.cityState,
                  accuracyMeters: liveLoc.accuracy,
                  freshness: liveLoc.isGpsLive ? 'Live GPS' : '2 min ago',
                  latitude: liveLoc.latitude,
                  longitude: liveLoc.longitude,
                  onDetailsTap: () => context.push('/location-details'),
                ),
                const SizedBox(height: AppSpacing.lg),

                // D. Central SOS Section (Safe Walk | Circular 3s SOS | Nearby Help)
                CentralSosSection(
                  onSosTriggered: () {
                    ref.read(sosProvider.notifier).triggerSOS(
                          type: EmergencyType.personalThreat,
                        );
                    ref.read(mainNavigationProvider.notifier).setTab(2);
                  },
                  onSosTap: () => ref.read(mainNavigationProvider.notifier).setTab(2),
                  onSafeWalkTap: () => context.push('/safewalk'),
                  onNearbyHelpTap: () => ref.read(mainNavigationProvider.notifier).setTab(1),
                ),
                const SizedBox(height: AppSpacing.lg),

                // E. Quick-Action Cards (2x2 Grid)
                Row(
                  children: [
                    // Card 1: Trusted Contacts (Purple)
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.people_alt_rounded,
                        accentColor: AppColors.purpleAccent,
                        title: 'Trusted Contacts',
                        subtitle: '${contacts.length} verified contacts',
                        onTap: () => context.push('/contacts'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Card 2: Emergency History (Amber)
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.history_rounded,
                        accentColor: AppColors.warningAmber,
                        title: 'Emergency History',
                        subtitle: activeSOS != null ? '1 active incident' : '3 past logs',
                        onTap: () => context.push('/history'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    // Card 3: Community (Green)
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.shield_rounded,
                        accentColor: AppColors.successGreen,
                        title: 'Community',
                        subtitle: '4 local reports',
                        onTap: () => ref.read(mainNavigationProvider.notifier).setTab(3),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Card 4: Report Something (Blue)
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.campaign_rounded,
                        accentColor: AppColors.primaryBlue,
                        title: 'Report Something',
                        subtitle: 'Help make places safer',
                        onTap: () => context.push('/report'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // F. Safe Walk Active-Session / Quick Start Card
                SafeWalkSessionCard(
                  isActive: safeWalk.isActive,
                  status: safeWalk.status,
                  destinationName: safeWalk.destinationName,
                  remainingSeconds: safeWalk.remainingCheckinSeconds,
                  onStartTap: () => context.push('/safewalk'),
                  onEndTap: () => ref.read(safeWalkProvider.notifier).complete(),
                ),
                const SizedBox(height: AppSpacing.md),

                // G. Safety Tip Card (Amber lightbulb)
                const SafetyTipCard(
                  title: 'Safety Tip',
                  tipText: 'Share your live location with a trusted contact when travelling alone at night.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
