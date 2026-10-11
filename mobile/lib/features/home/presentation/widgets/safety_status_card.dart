import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/widgets/gradient_icon_box.dart';

class SafetyStatusCard extends StatelessWidget {
  final bool hasLocationPermission;
  final bool isNetworkConnected;
  final String locationFreshnessText;
  final String lastUpdatedText;
  final VoidCallback? onTap;

  const SafetyStatusCard({
    super.key,
    this.hasLocationPermission = true,
    this.isNetworkConnected = true,
    this.locationFreshnessText = 'Location available',
    this.lastUpdatedText = 'Updated 2m ago',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          // Left: Safety Status with Green Shield
          Expanded(
            child: Row(
              children: [
                GradientIconBox(
                  icon: Icons.verified_user_rounded,
                  iconColor: AppColors.successGreen,
                  size: 36,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Safety status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLocationPermission ? locationFreshnessText : 'Location permission required',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasLocationPermission ? AppColors.secondaryText : AppColors.warningAmber,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vertical divider
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.glassBorder,
          ),

          // Right: Connectivity State
          Expanded(
            child: Row(
              children: [
                GradientIconBox(
                  icon: isNetworkConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  iconColor: isNetworkConnected ? AppColors.cyan : AppColors.warningAmber,
                  size: 36,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNetworkConnected ? 'Connected' : 'Offline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastUpdatedText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
