import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.glassBorder)),
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.primaryText)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: const InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(color: AppColors.secondaryText),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
        title: Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, color: AppColors.warningAmber),
            SizedBox(width: 8),
            Text('GuardVarX Premium', style: TextStyle(color: AppColors.primaryText)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Upgrade unlocks:', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
            SizedBox(height: 8),
            Text('• 24/7 Monitored Safe Walk Emergency Dispatch', style: TextStyle(color: Colors.white, fontSize: 12)),
            SizedBox(height: 4),
            Text('• Unlimited Offline Mesh Relay Hops', style: TextStyle(color: Colors.white, fontSize: 12)),
            SizedBox(height: 4),
            Text('• Priority SMS Gateway with Zero Delay', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.secondaryText))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Subscribe ₹99/mo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.glassBorder)),
        title: Text(title, style: const TextStyle(color: AppColors.primaryText)),
        content: Text(body, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.primaryBlue))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final displayName = user.isAuthenticated && user.displayName.isNotEmpty ? user.displayName : 'Priyavarathan P';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Header (GuardVarX / Profile + Bell + Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 18),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            ref.read(mainNavigationProvider.notifier).handleBack();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Guard',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'VarX',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryText, size: 24),
                        onPressed: () => context.push('/notifications'),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF1E293B),
                          child: Icon(Icons.person, color: AppColors.primaryText, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // B. Main User Profile Card
              GlassCard(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar with camera badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryBlue, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 34,
                            backgroundColor: Color(0xFF1E293B),
                            child: Icon(Icons.person, size: 38, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 16, color: AppColors.primaryBlue),
                            ],
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(const ClipboardData(text: '@CVX10245'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('GuardVarX Handle @CVX10245 copied to clipboard')),
                              );
                            },
                            child: Row(
                              children: const [
                                Text('@CVX10245', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                                SizedBox(width: 4),
                                Icon(Icons.copy_rounded, size: 12, color: AppColors.secondaryText),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: const [
                              Icon(Icons.location_on_rounded, size: 12, color: AppColors.secondaryText),
                              SizedBox(width: 2),
                              Text('Chennai, Tamil Nadu', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(Icons.circle, size: 8, color: AppColors.successGreen),
                              SizedBox(width: 4),
                              Text('Active', style: TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Edit Profile button
                    GestureDetector(
                      onTap: () => _showEditProfileDialog(context, displayName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.elevatedGlassSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // C. 4 Stats Row (Trusted Contacts, Emergencies, Safe Walk, Community)
              Row(
                children: [
                  _buildStatCard('3', 'Trusted\nContacts', Icons.people_alt_rounded, AppColors.purpleAccent),
                  const SizedBox(width: 8),
                  _buildStatCard('2', 'Emergencies\nThis Month', Icons.notifications_active_rounded, AppColors.emergencyRed),
                  const SizedBox(width: 8),
                  _buildStatCard('1', 'Safe Walk\nCompleted', Icons.shield_rounded, AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  _buildStatCard('12', 'Community\nContributions', Icons.star_rounded, AppColors.successGreen),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // D. GuardVarX Free Upgrade Banner
              GlassCard(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.warningAmber, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(text: 'Guard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                TextSpan(text: 'VarX', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                                TextSpan(text: ' Free', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('Upgrade to Premium for advanced safety features.',
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warningAmber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _showUpgradeDialog(context),
                      child: const Text('Upgrade', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // E. 4 Quick Settings Grid
              Row(
                children: [
                  Expanded(
                    child: _buildQuickSettingCard('Trusted\nContacts', Icons.people_alt_rounded, AppColors.purpleAccent, () {
                      context.push('/contacts');
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickSettingCard('Emergency\nHistory', Icons.history_rounded, AppColors.primaryBlue, () {
                      context.push('/history');
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickSettingCard('Safety\nSettings', Icons.shield_rounded, AppColors.successGreen, () {
                      _showInfoDialog(context, 'Safety Settings',
                          '• Duress PIN is active.\n• BLE Mesh packet relay is enabled.\n• Silent volume button trigger is set.');
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickSettingCard('My\nReports', Icons.file_download_outlined, AppColors.warningAmber, () {
                      _showInfoDialog(context, 'My Reports', 'You have contributed 2 verified road hazards in Chennai.');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // F. Settings List Items
              _buildSettingItem(
                icon: Icons.security_rounded,
                iconColor: AppColors.primaryBlue,
                title: 'Privacy & Security',
                subtitle: 'Control your data, permissions and security',
                onTap: () {
                  _showInfoDialog(context, 'Privacy & Security',
                      'GuardVarX enforces strict 24-hour coordinate TTL pruning. Your live coordinates are niemals sold or stored permanently.');
                },
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.cyan,
                title: 'Location Sharing',
                subtitle: 'Manage location access and sharing',
                onTap: () => context.push('/location-details'),
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.emergencyRed,
                title: 'Notifications',
                subtitle: 'Alert preferences and notification settings',
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.settings_rounded,
                iconColor: AppColors.primaryBlue,
                title: 'App Permissions',
                subtitle: 'Location, camera, notifications and connectivity',
                onTap: () {
                  _showInfoDialog(context, 'App Permissions',
                      '• Location: Granted (Always)\n• Bluetooth: Granted (Nearby Mesh)\n• SMS: Granted (Offline Fallback)');
                },
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.cyan,
                title: 'Help & Support',
                subtitle: 'FAQs, support and emergency guidance',
                onTap: () {
                  _showInfoDialog(context, 'Emergency Helpline Numbers (India)',
                      '• All Emergency: 112\n• Women Helpline: 1091\n• Ambulance / Medical: 108\n• Police: 100\n• National Disaster Management: 1078');
                },
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.share_rounded,
                iconColor: AppColors.warningAmber,
                title: 'Share GuardVarX',
                subtitle: 'Invite friends and help build a safer community',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied: https://guardvarx.app/download')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // G. Logout & Delete Account Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).signOut();
                        context.go('/auth');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.emergencyRed.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.logout_rounded, color: AppColors.emergencyRed, size: 16),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showInfoDialog(context, 'Delete Account',
                            'Account deletion requires two-factor verification. Contact privacy@guardvarx.in.');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C0A0E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.delete_outline_rounded, color: AppColors.secondaryText, size: 16),
                            SizedBox(width: 8),
                            Text('Delete Account', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // H. Footer
              Center(
                child: Text(
                  'Version 1.0.0  |  Terms of Service  |  Privacy Policy',
                  style: TextStyle(color: AppColors.secondaryText.withOpacity(0.6), fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        borderRadius: 14.0,
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 9, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSettingCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderRadius: 14.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.15)),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16.0,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 18),
        ],
      ),
    );
  }
}
