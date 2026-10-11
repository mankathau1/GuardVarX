import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CyberRoboticHandWidget extends StatelessWidget {
  final Offset position;
  final bool isTapping;
  final bool isLongPressing;
  final double longPressProgress; // 0.0 to 1.0
  final double tapProgress;
  final String actionBadge;

  const CyberRoboticHandWidget({
    super.key,
    required this.position,
    required this.isTapping,
    this.isLongPressing = false,
    this.longPressProgress = 0.0,
    required this.tapProgress,
    this.actionBadge = '',
  });

  @override
  Widget build(BuildContext context) {
    // The index fingertip is at (24, 12) relative to the container
    return Positioned(
      left: position.dx - 24,
      top: position.dy - 12,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Long Press Circular Countdown Arc & Energy Rings (When holding SOS for 3s)
            if (isLongPressing)
              Positioned(
                left: 24,
                top: 12,
                child: CustomPaint(
                  painter: _LongPressProgressPainter(progress: longPressProgress),
                ),
              ),

            // 2. Expanding Touch Shockwave Ripple at Fingertip (when tapping)
            if ((isTapping || tapProgress > 0.05) && !isLongPressing)
              Positioned(
                left: 24,
                top: 12,
                child: CustomPaint(
                  painter: _ShockwavePainter(progress: tapProgress),
                ),
              ),

            // 3. Action Badge floating above fingertip
            if (actionBadge.isNotEmpty)
              Positioned(
                left: 36,
                top: isLongPressing ? -36 : -26,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLongPressing ? const Color(0xFF10B981) : AppColors.cyan,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLongPressing ? const Color(0xFF10B981) : AppColors.cyan).withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLongPressing ? Icons.timer_rounded : Icons.touch_app_rounded,
                        color: isLongPressing ? const Color(0xFF10B981) : AppColors.cyan,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        actionBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Cyber Robotic Hand & Pointer Finger
            Transform.translate(
              offset: Offset(0, (isTapping || isLongPressing) ? 6 : 0),
              child: Transform.scale(
                scale: (isTapping || isLongPressing) ? 0.92 : 1.0,
                origin: const Offset(24, 12),
                child: SizedBox(
                  width: 110,
                  height: 140,
                  child: CustomPaint(
                    painter: _RoboticHandPainter(
                      isTapping: isTapping || isLongPressing,
                      isLongPressing: isLongPressing,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LongPressProgressPainter extends CustomPainter {
  final double progress;

  _LongPressProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 38.0;

    // Background track ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(Offset.zero, radius, bgPaint);

    // Glowing Neon Green progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF10B981), Color(0xFFFF2A4B)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;

    final sweepAngle = (progress.clamp(0.0, 1.0)) * 6.2831853; // 2 * PI
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      -1.570796, // Start from top (-90 deg)
      sweepAngle,
      false,
      progressPaint,
    );

    // Outer pulsating aura ring
    final auraPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius + 8, auraPaint);
  }

  @override
  bool shouldRepaint(covariant _LongPressProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ShockwavePainter extends CustomPainter {
  final double progress;

  _ShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final radius = 10.0 + (progress * 55.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Outer Shockwave Ring
    final wavePaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset.zero, radius, wavePaint);

    // Inner Secondary Ring
    final innerPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius * 0.6, innerPaint);

    // Central Contact Flash
    final flashPaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 6 * (1.0 - progress), flashPaint);
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RoboticHandPainter extends CustomPainter {
  final bool isTapping;
  final bool isLongPressing;

  _RoboticHandPainter({required this.isTapping, this.isLongPressing = false});

  @override
  void paint(Canvas canvas, Size size) {
    const tipX = 24.0;
    const tipY = 12.0;

    final neonColor = isLongPressing
        ? const Color(0xFF10B981) // Neon Green during long press
        : (isTapping ? const Color(0xFFFF2A4B) : const Color(0xFF00E5FF));

    // A. Drop Shadow beneath hand
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final shadowPath = Path()
      ..moveTo(tipX + 8, tipY + 14)
      ..lineTo(tipX + 28, tipY + 50)
      ..lineTo(tipX + 55, tipY + 95)
      ..lineTo(tipX + 80, tipY + 115)
      ..lineTo(tipX + 60, tipY + 130)
      ..lineTo(tipX + 30, tipY + 105)
      ..lineTo(tipX + 15, tipY + 60)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // B. Robotic Hand Armor & Joint Lines
    final armorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF334155),
          Color(0xFF1E293B),
          Color(0xFF0F172A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = neonColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Index Finger Phalanges (Main pointing finger)
    final fingerPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(tipX + 12, tipY + 4)
      ..lineTo(tipX + 22, tipY + 28)
      ..lineTo(tipX + 28, tipY + 52)
      ..lineTo(tipX + 42, tipY + 78)
      ..lineTo(tipX + 70, tipY + 95)
      ..lineTo(tipX + 74, tipY + 118)
      ..lineTo(tipX + 48, tipY + 128)
      ..lineTo(tipX + 24, tipY + 98)
      ..lineTo(tipX + 16, tipY + 62)
      ..lineTo(tipX + 10, tipY + 34)
      ..lineTo(tipX - 2, tipY + 10)
      ..close();

    canvas.drawPath(fingerPath, armorPaint);
    canvas.drawPath(fingerPath, borderPaint);

    // Neon Seams & Cyber Grooves
    final seamPaint = Paint()
      ..color = neonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(tipX + 5, tipY + 20), const Offset(tipX + 16, tipY + 24), seamPaint);
    canvas.drawLine(const Offset(tipX + 13, tipY + 42), const Offset(tipX + 25, tipY + 47), seamPaint);
    canvas.drawLine(const Offset(tipX + 20, tipY + 68), const Offset(tipX + 36, tipY + 74), seamPaint);

    // Glowing Cyber Knuckle Nodes
    final nodePaint = Paint()
      ..color = neonColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(tipX + 11, tipY + 22), 2.5, nodePaint);
    canvas.drawCircle(const Offset(tipX + 19, tipY + 45), 3.0, nodePaint);
    canvas.drawCircle(const Offset(tipX + 28, tipY + 71), 3.5, nodePaint);

    // Fingertip Laser Contact Sensor
    final tipAura = Paint()
      ..color = neonColor.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(tipX, tipY), 7, tipAura);

    final tipCore = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(tipX, tipY), 3.5, tipCore);

    // Laser crosshair dot
    final crossPaint = Paint()
      ..color = neonColor
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(tipX - 7, tipY), const Offset(tipX + 7, tipY), crossPaint);
    canvas.drawLine(const Offset(tipX, tipY - 7), const Offset(tipX, tipY + 7), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _RoboticHandPainter oldDelegate) {
    return oldDelegate.isTapping != isTapping || oldDelegate.isLongPressing != isLongPressing;
  }
}
