import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class GradientIconBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? borderColor;

  const GradientIconBox({
    super.key,
    required this.icon,
    required this.iconColor,
    this.backgroundColor,
    this.gradient,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.borderRadius = AppSpacing.radiusSm,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? iconColor.withValues(alpha: 0.15)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? iconColor.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
