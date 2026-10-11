import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class DeliberateHoldButton extends StatefulWidget {
  final VoidCallback onTrigger;
  final Duration holdDuration;

  const DeliberateHoldButton({
    super.key,
    required this.onTrigger,
    this.holdDuration = const Duration(seconds: 3),
  });

  @override
  State<DeliberateHoldButton> createState() => _DeliberateHoldButtonState();
}

class _DeliberateHoldButtonState extends State<DeliberateHoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _vibrateTimer;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _vibrateTimer?.cancel();
        if (mounted) {
          setState(() => _isHolding = false);
        }
        HapticFeedback.heavyImpact();
        widget.onTrigger();
      }
    });
  }

  void _startHolding() {
    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _animController.forward(from: 0.0);

    _vibrateTimer?.cancel();
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      HapticFeedback.selectionClick();
    });
  }

  void _stopHolding() {
    if (_isHolding) {
      setState(() => _isHolding = false);
      _vibrateTimer?.cancel();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _vibrateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _startHolding(),
          onPointerUp: (_) => _stopHolding(),
          onPointerCancel: (_) => _stopHolding(),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final progress = _animController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow & Pulsing Ring
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRedGlow.withOpacity(_isHolding ? 0.8 : 0.3),
                          blurRadius: _isHolding ? 40 : 20,
                          spreadRadius: _isHolding ? 8 : 2,
                        ),
                      ],
                    ),
                  ),

                  // Progress circular border
                  SizedBox(
                    width: 164,
                    height: 164,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppColors.glassBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emergencyRed),
                    ),
                  ),

                  // Center SOS core button
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isHolding
                            ? [const Color(0xFFFF1744), const Color(0xFFB71C1C)]
                            : [const Color(0xFF261014), const Color(0xFF14080A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: _isHolding ? Colors.white.withOpacity(0.4) : AppColors.glassBorderElevated,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emergency_rounded,
                          color: AppColors.primaryText,
                          size: 40,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isHolding ? '${((1 - progress) * 3).ceil()}s' : 'HOLD SOS',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
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
        const SizedBox(height: 16),
        const Text(
          'Press and hold for 3 seconds to send emergency alert',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
