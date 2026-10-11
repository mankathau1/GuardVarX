import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RobotAvatarWidget extends StatefulWidget {
  final double size;
  final bool isSpeaking;
  final bool isEmergencyMode;
  final String statusText;

  const RobotAvatarWidget({
    super.key,
    this.size = 90,
    this.isSpeaking = true,
    this.isEmergencyMode = false,
    this.statusText = 'IM GUARD ACTIVE',
  });

  @override
  State<RobotAvatarWidget> createState() => _RobotAvatarWidgetState();
}

class _RobotAvatarWidgetState extends State<RobotAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final floatOffset = math.sin(_animController.value * math.pi) * 5;
        final glowPulse = 0.6 + (_animController.value * 0.4);

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _CyberRobotPainter(
                    pulse: glowPulse,
                    isEmergency: widget.isEmergencyMode,
                  ),
                ),
              ),
              if (widget.statusText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (widget.isEmergencyMode ? AppColors.emergencyRed : AppColors.cyan)
                        .withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.isEmergencyMode ? AppColors.emergencyRed : AppColors.cyan,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.statusText,
                    style: TextStyle(
                      color: widget.isEmergencyMode ? AppColors.emergencyRed : AppColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CyberRobotPainter extends CustomPainter {
  final double pulse;
  final bool isEmergency;

  _CyberRobotPainter({required this.pulse, required this.isEmergency});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final primaryColor = isEmergency ? const Color(0xFFFF2A4B) : const Color(0xFF00E5FF);
    final secondaryColor = isEmergency ? const Color(0xFFFFA000) : const Color(0xFF1E88E5);

    // 1. Outer Hologram Ambient Aura
    final auraPaint = Paint()
      ..color = primaryColor.withOpacity(0.2 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, size.width * 0.45, auraPaint);

    // 2. Hologram Halo Ring
    final ringPaint = Paint()
      ..color = primaryColor.withOpacity(0.4 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, size.width * 0.42, ringPaint);

    // 3. Robot Head Armor (Rounded Cyber Hexagon)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * 0.65, height: size.height * 0.6),
      const Radius.circular(16),
    );
    final headPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E293B),
          const Color(0xFF0F172A),
        ],
      ).createShader(headRect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(headRect, headPaint);

    // Head border glow
    final headBorder = Paint()
      ..color = primaryColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(headRect, headBorder);

    // 4. Ears / Antenna Nodes
    final earPaint = Paint()..color = secondaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - (size.width * 0.35), center.dy),
          width: 5,
          height: 16,
        ),
        const Radius.circular(3),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + (size.width * 0.35), center.dy),
          width: 5,
          height: 16,
        ),
        const Radius.circular(3),
      ),
      earPaint,
    );

    // 5. Cyber Visor / Eyes (Glowing Horizontal Strip)
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 3),
        width: size.width * 0.45,
        height: 14,
      ),
      const Radius.circular(8),
    );
    final visorPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor, primaryColor],
      ).createShader(visorRect.outerRect);
    canvas.drawRRect(visorRect, visorPaint);

    // Visor Twin Eye Nodes
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx - 8, center.dy - 3), 2.5, eyePaint);
    canvas.drawCircle(Offset(center.dx + 8, center.dy - 3), 2.5, eyePaint);

    // 6. Soundwave / Mouth Grid
    final mouthPaint = Paint()
      ..color = primaryColor.withOpacity(0.7 * pulse)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final mouthY = center.dy + 12;
    canvas.drawLine(Offset(center.dx - 10, mouthY), Offset(center.dx - 10, mouthY + 3), mouthPaint);
    canvas.drawLine(Offset(center.dx - 5, mouthY - 1), Offset(center.dx - 5, mouthY + 4), mouthPaint);
    canvas.drawLine(Offset(center.dx, mouthY - 3), Offset(center.dx, mouthY + 5), mouthPaint);
    canvas.drawLine(Offset(center.dx + 5, mouthY - 1), Offset(center.dx + 5, mouthY + 4), mouthPaint);
    canvas.drawLine(Offset(center.dx + 10, mouthY), Offset(center.dx + 10, mouthY + 3), mouthPaint);

    // 7. Forehead Crest Glyph (VarX Shield symbol)
    final crestPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(center.dx - 6, center.dy - 17)
      ..lineTo(center.dx, center.dy - 22)
      ..lineTo(center.dx + 6, center.dy - 17)
      ..lineTo(center.dx, center.dy - 13)
      ..close();
    canvas.drawPath(path, crestPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberRobotPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.isEmergency != isEmergency;
  }
}
