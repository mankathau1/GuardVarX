import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/widgets/gradient_icon_box.dart';

class CentralSosSection extends StatefulWidget {
  final VoidCallback onSosTriggered;
  final VoidCallback onSafeWalkTap;
  final VoidCallback onNearbyHelpTap;
  final VoidCallback? onSosTap;
  final Duration holdDuration;

  const CentralSosSection({
    super.key,
    required this.onSosTriggered,
    required this.onSafeWalkTap,
    required this.onNearbyHelpTap,
    this.onSosTap,
    this.holdDuration = const Duration(seconds: 3),
  });

  @override
  State<CentralSosSection> createState() => _CentralSosSectionState();
}

class _CentralSosSectionState extends State<CentralSosSection> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _hapticTimer;
  bool _isHolding = false;
  DateTime? _pointerDownTime;
  Offset? _pointerDownPos;
  bool _movedTooFar = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hapticTimer?.cancel();
        if (mounted) {
          setState(() => _isHolding = false);
        }
        HapticFeedback.heavyImpact();
        widget.onSosTriggered();
      }
    });
  }

  void _startHolding(Offset pos) {
    _pointerDownPos = pos;
    _movedTooFar = false;
    _pointerDownTime = DateTime.now();
    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _animController.forward(from: 0.0);

    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      HapticFeedback.selectionClick();
    });
  }

  void _onPointerMove(Offset pos) {
    if (_pointerDownPos != null && (pos - _pointerDownPos!).distance > 18.0) {
      _movedTooFar = true;
    }
  }

  void _stopHolding() {
    if (_isHolding) {
      final elapsed = _pointerDownTime != null
          ? DateTime.now().difference(_pointerDownTime!)
          : Duration.zero;
      final wasQuickTap = !_movedTooFar && elapsed.inMilliseconds < 400;
      setState(() => _isHolding = false);
      _hapticTimer?.cancel();
      _animController.reset();

      // If user tapped quickly without dragging or holding, open SOS view
      if (wasQuickTap && widget.onSosTap != null) {
        widget.onSosTap!();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _hapticTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: Safe Walk
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              borderRadius: AppSpacing.radiusLg,
              onTap: widget.onSafeWalkTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GradientIconBox(
                    icon: Icons.directions_walk_rounded,
                    iconColor: AppColors.primaryBlue,
                    size: 34,
                    iconSize: 18,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Safe Walk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Share journey',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Center: Circular SOS Control with Concentric Rings
          SizedBox(
            width: 136,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _startHolding(e.position),
                  onPointerMove: (e) => _onPointerMove(e.position),
                  onPointerUp: (_) => _stopHolding(),
                  onPointerCancel: (_) => _stopHolding(),
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final progress = _animController.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outermost subtle concentric ring
                          Container(
                            width: 134,
                            height: 134,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.emergencyRed.withValues(alpha: _isHolding ? 0.4 : 0.15),
                                width: 1.5,
                              ),
                            ),
                          ),

                          // Middle concentric ring with ambient glow
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.emergencyRed.withValues(alpha: _isHolding ? 0.6 : 0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emergencyRedGlow.withValues(alpha: _isHolding ? 0.8 : 0.35),
                                  blurRadius: _isHolding ? 24 : 14,
                                  spreadRadius: _isHolding ? 3 : 1,
                                ),
                              ],
                            ),
                          ),

                          // Circular Progress Indicator for deliberate hold
                          SizedBox(
                            width: 108,
                            height: 108,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4.0,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),

                          // Center Core SOS Button
                          Container(
                            width: 102,
                            height: 102,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF2A55), // Bright red
                                  Color(0xFFC40E2F), // Deep rich crimson
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 2.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.warning_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isHolding
                                      ? '${((1 - progress) * 3).ceil()}s'
                                      : 'SOS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: widget.onSosTap,
                  child: const Text(
                    'Hold for 3 seconds',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right Card: Nearby Help
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              borderRadius: AppSpacing.radiusLg,
              onTap: widget.onNearbyHelpTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GradientIconBox(
                    icon: Icons.people_outline_rounded,
                    iconColor: AppColors.cyan,
                    size: 34,
                    iconSize: 18,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Nearby Help',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Find trusted people',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
