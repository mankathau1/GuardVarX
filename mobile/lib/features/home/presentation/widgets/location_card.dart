import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/widgets/gradient_icon_box.dart';

class LocationCard extends StatelessWidget {
  final String address;
  final String cityState;
  final double accuracyMeters;
  final String freshness;
  final bool isPermissionGranted;
  final VoidCallback onDetailsTap;

  const LocationCard({
    super.key,
    this.address = 'Sector 62, Electronic City',
    this.cityState = 'Noida, Uttar Pradesh',
    this.accuracyMeters = 8.0,
    this.freshness = 'Just now',
    this.isPermissionGranted = true,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onDetailsTap,
      backgroundColor: AppColors.locationCardBackground,
      borderColor: AppColors.locationCardBorder,
      glowColor: AppColors.blueGlow,
      glowRadius: 16,
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(18.0),
      child: Stack(
        children: [
          // Subtle ambient map line graphic in the background
          Positioned(
            right: -10,
            bottom: -15,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.map_rounded,
                size: 110,
                color: AppColors.cyan,
              ),
            ),
          ),

          // Main Card Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GradientIconBox(
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.primaryBlue,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                        size: 34,
                        iconSize: 18,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  // Open location details chevron
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.secondaryText,
                      size: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (isPermissionGranted) ...[
                Text(
                  address,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cityState,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedGlassSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded, color: AppColors.cyan, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            '± ${accuracyMeters.toStringAsFixed(0)}m accuracy',
                            style: const TextStyle(
                              color: AppColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $freshness',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'Location Access Required',
                  style: TextStyle(
                    color: AppColors.warningAmber,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to grant permission to share location with trusted contacts in an emergency.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
