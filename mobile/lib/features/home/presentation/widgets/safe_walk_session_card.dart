import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/widgets/gradient_icon_box.dart';

class SafeWalkSessionCard extends StatelessWidget {
  final bool isActive;
  final String status;
  final String destinationName;
  final int remainingSeconds;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const SafeWalkSessionCard({
    super.key,
    required this.isActive,
    this.status = 'INACTIVE',
    this.destinationName = '',
    this.remainingSeconds = 0,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      borderColor: isActive
          ? (status == 'WARNING' ? AppColors.warningAmber : AppColors.primaryBlue.withValues(alpha: 0.6))
          : AppColors.glassBorder,
      child: Row(
        children: [
          GradientIconBox(
            icon: Icons.navigation_rounded,
            iconColor: AppColors.primaryBlue,
            size: 40,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Safe Walk',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'WARNING'
                              ? AppColors.warningAmber.withValues(alpha: 0.2)
                              : AppColors.successGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'WARNING' ? AppColors.warningAmber : AppColors.successGreen,
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
                  isActive
                      ? 'Destination: $destinationName (${remainingSeconds ~/ 60}m remaining)'
                      : 'Start a safe journey to share your live location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Start or End CTA
          if (!isActive)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onStartTap,
              child: const Text(
                'Start',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.emergencyRed),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onEndTap,
              child: const Text(
                'End',
                style: TextStyle(color: AppColors.emergencyRed, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
