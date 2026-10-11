import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../safe_walk/providers/safe_walk_provider.dart';
import '../../sos/domain/emergency_model.dart';
import '../../sos/providers/sos_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/safety_status_card.dart';
import 'widgets/location_card.dart';
import 'widgets/central_sos_section.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/safe_walk_session_card.dart';
import 'widgets/safety_tip_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final activeSOS = ref.watch(sosProvider);
    final safeWalk = ref.watch(safeWalkProvider);
    final contacts = ref.watch(contactsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 100.0), // Padding above floating bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. Header
                HomeHeader(
                  userName: user.isAuthenticated ? user.displayName : 'Priya',
                  unreadNotificationsCount: 1,
                  onNotificationsTap: () => context.push('/notifications'),
                  onProfileTap: () => context.go('/profile'),
                ),
                const SizedBox(height: AppSpacing.md),

                // B. Safety & Connectivity Status Card
                SafetyStatusCard(
                  hasLocationPermission: true,
                  isNetworkConnected: true,
                  locationFreshnessText: 'Location available',
                  lastUpdatedText: 'Updated 2m ago',
                  onTap: () => context.push('/location-details'),
                ),
                const SizedBox(height: AppSpacing.md),

                // C. Current Location Card
                LocationCard(
                  address: 'Sector 62, Electronic City',
                  cityState: 'Noida, Uttar Pradesh',
                  accuracyMeters: 8.0,
                  freshness: 'Just now',
                  onDetailsTap: () => context.push('/location-details'),
                ),
                const SizedBox(height: AppSpacing.lg),

                // D. Central SOS Section (Safe Walk | Circular 3s SOS | Nearby Help)
                CentralSosSection(
                  onSosTriggered: () {
                    ref.read(sosProvider.notifier).triggerSOS(
                          type: EmergencyType.personalThreat,
                        );
                    context.go('/sos');
                  },
                  onSafeWalkTap: () => context.push('/safewalk'),
                  onNearbyHelpTap: () => context.go('/nearby'),
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
                        onTap: () => context.go('/community'),
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
