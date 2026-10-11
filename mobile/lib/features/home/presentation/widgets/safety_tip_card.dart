import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/widgets/gradient_icon_box.dart';

class SafetyTipCard extends StatelessWidget {
  final String title;
  final String tipText;
  final VoidCallback? onTap;

  const SafetyTipCard({
    super.key,
    this.title = 'Safety Tip',
    this.tipText = 'Share your live location with a trusted contact when travelling alone at night.',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(16.0),
      borderColor: AppColors.warningAmber.withValues(alpha: 0.35),
      glowColor: AppColors.amberGlow,
      glowRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBox(
            icon: Icons.lightbulb_rounded,
            iconColor: AppColors.warningAmber,
            backgroundColor: AppColors.warningAmber.withValues(alpha: 0.15),
            borderColor: AppColors.warningAmber.withValues(alpha: 0.3),
            size: 38,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.warningAmber,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipText,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12.5,
                    height: 1.4,
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
