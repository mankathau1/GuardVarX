import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

class LocationDetailsScreen extends StatefulWidget {
  const LocationDetailsScreen({super.key});

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  final TransformationController _transformController = TransformationController();
  String _mapStyle = 'Dark Standard';
  bool _isCopied = false;

  // Anna Salai, Teynampet, Chennai coordinates
  static const double _latitude = 13.040517;
  static const double _longitude = 80.250328;
  static const String _address = 'Anna Salai, Teynampet, Chennai, Tamil Nadu 600018';

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _recenter() {
    setState(() {
      _transformController.value = Matrix4.identity();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surface,
        duration: Duration(seconds: 1),
        content: Text('Centered to Anna Salai, Teynampet', style: TextStyle(color: AppColors.cyan)),
      ),
    );
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 3.5) {
      final matrix = _transformController.value.clone()..scale(1.25);
      _transformController.value = matrix;
    }
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 0.8) {
      final matrix = _transformController.value.clone()..scale(0.8);
      _transformController.value = matrix;
    }
  }

  Future<void> _launchGoogleMaps() async {
    final geoUri = Uri.parse('geo:$_latitude,$_longitude?q=$_latitude,$_longitude(Current+Location+-+Anna+Salai)');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error launching Google Maps: $e')),
          );
        }
      }
    }
  }

  void _copyCoordinates() {
    Clipboard.setData(const ClipboardData(text: '$_latitude, $_longitude'));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surface,
        duration: Duration(seconds: 2),
        content: Text('Coordinates copied to clipboard (13.040517, 80.250328)', style: TextStyle(color: AppColors.successGreen)),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _shareLocation() {
    final shareText = 'My live emergency location: https://maps.google.com/?q=$_latitude,$_longitude\nAccuracy: 12m • GuardVarX';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surface,
        duration: Duration(seconds: 2),
        content: Text('Live Google Maps link copied to share', style: TextStyle(color: AppColors.cyan)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Full-screen Interactive Google Map View
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.7,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(200),
              child: SizedBox(
                width: 1200,
                height: 1200,
                child: CustomPaint(
                  painter: _GoogleMapFullInteractivePainter(style: _mapStyle),
                ),
              ),
            ),
          ),

          // 2. Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xCC08121E),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primaryText,
                          size: 18,
                        ),
                      ),
                    ),

                    // Map Title Pill with Google Logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xCC08121E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.map_rounded, color: AppColors.primaryBlue, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Google Maps • Live Fix',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Style selector popup
                    PopupMenuButton<String>(
                      initialValue: _mapStyle,
                      onSelected: (val) => setState(() => _mapStyle = val),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.glassBorder),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xCC08121E),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(
                          Icons.layers_rounded,
                          color: AppColors.cyan,
                          size: 18,
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'Dark Standard',
                          child: Text('Dark Standard', style: TextStyle(color: Colors.white)),
                        ),
                        const PopupMenuItem(
                          value: 'Satellite',
                          child: Text('Satellite View', style: TextStyle(color: Colors.white)),
                        ),
                        const PopupMenuItem(
                          value: 'Terrain',
                          child: Text('Terrain & Metro', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Map Controls (Zoom +, Zoom -, Recenter GPS)
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  iconColor: AppColors.cyan,
                  onTap: _recenter,
                  tooltip: 'Center GPS',
                ),
                const SizedBox(height: 10),
                _buildMapControlBtn(
                  icon: Icons.add_rounded,
                  iconColor: Colors.white,
                  onTap: _zoomIn,
                  tooltip: 'Zoom In',
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.remove_rounded,
                  iconColor: Colors.white,
                  onTap: _zoomOut,
                  tooltip: 'Zoom Out',
                ),
              ],
            ),
          ),

          // 4. Google Attribution Badge
          Positioned(
            left: 18,
            bottom: 235,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Google Maps Imagery',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 5. Bottom Location Detail Glass Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              backgroundColor: const Color(0xEB0A1422),
              borderColor: AppColors.glassBorder,
              glowColor: AppColors.blueGlow,
              glowRadius: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address & GPS accuracy pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Anna Salai, Teynampet',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _address,
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan.withOpacity(0.35)),
                        ),
                        child: const Text(
                          '± 12 m GPS',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Coordinates row with copy button
                  GestureDetector(
                    onTap: _copyCoordinates,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedGlassSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.gps_fixed_rounded, color: AppColors.secondaryText, size: 14),
                              SizedBox(width: 6),
                              Text(
                                '13.040517° N, 80.250328° E',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _isCopied ? 'Copied!' : 'Tap to copy',
                            style: TextStyle(
                              color: _isCopied ? AppColors.successGreen : AppColors.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons: Open in Google Maps & Share Live Location
                  Row(
                    children: [
                      // Primary Button: Open in Google Maps
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _launchGoogleMaps,
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text(
                            'Open in Google Maps',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Secondary Button: Share Location
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            side: const BorderSide(color: AppColors.cyan, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _shareLocation,
                          icon: const Icon(Icons.share_rounded, size: 15),
                          label: const Text(
                            'Share Link',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
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

  Widget _buildMapControlBtn({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xEB0A1422),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

/// Full interactive canvas rendering an authentic Dark Theme Google Map
/// with Chennai street layout, metro track, arterial Anna Salai, landmarks, and live user marker.
class _GoogleMapFullInteractivePainter extends CustomPainter {
  final String style;

  _GoogleMapFullInteractivePainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final bool isSatellite = style == 'Satellite';
    final Color bgColor = isSatellite ? const Color(0xFF07141E) : const Color(0xFF0A121F);

    // 1. Base Ground Fill
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Blocks & Urban Parcels
    final parcelPaint = Paint()
      ..color = isSatellite ? const Color(0xFF0B1F2C) : const Color(0xFF0F1B2C)
      ..style = PaintingStyle.fill;

    // Draw various urban parcels across map
    for (double x = 40; x < size.width; x += 180) {
      for (double y = 40; y < size.height; y += 160) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 140, 110), const Radius.circular(8)),
          parcelPaint,
        );
      }
    }

    // 3. Green Park (Semmozhi Poonga nearby on Cathedral Road)
    final parkPaint = Paint()
      ..color = const Color(0xFF0E2E28)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.48, size.height * 0.22, 190, 130), const Radius.circular(16)),
      parkPaint,
    );

    // 4. Minor Grid Streets
    final minorStreetPaint = Paint()
      ..color = const Color(0xFF162539)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (double i = 0; i <= size.width; i += 90) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), minorStreetPaint);
    }
    for (double i = 0; i <= size.height; i += 90) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), minorStreetPaint);
    }

    // 5. Secondary Crossings (Eldams Road, Cenotaph Road)
    final secRoadPaint = Paint()
      ..color = const Color(0xFF1E3550)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    // Eldams Road horizontal
    canvas.drawLine(Offset(0, size.height * 0.52), Offset(size.width, size.height * 0.49), secRoadPaint);
    // Chamiers Road
    canvas.drawLine(Offset(0, size.height * 0.68), Offset(size.width, size.height * 0.66), secRoadPaint);
    // Cathedral Road
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.38), secRoadPaint);

    // 6. Metro Line (Chennai Metro Phase 1 AG-DMS underground track)
    final metroPaint = Paint()
      ..color = const Color(0xFF00B0FF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.28, size.height),
      Offset(size.width * 0.72, 0),
      metroPaint,
    );

    // 7. Main Arterial Highway: Anna Salai (Mount Road)
    final mainArteryPaint = Paint()
      ..color = const Color(0xFF2C4C72)
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final annaSalaiStart = Offset(size.width * 0.24, size.height);
    final annaSalaiEnd = Offset(size.width * 0.76, 0);
    canvas.drawLine(annaSalaiStart, annaSalaiEnd, mainArteryPaint);

    // Anna Salai central dividing median line
    final medianPaint = Paint()
      ..color = const Color(0xFF456F9E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(annaSalaiStart, annaSalaiEnd, medianPaint);

    // 8. Landmark Markers & Labels
    _drawLandmark(
      canvas,
      pos: Offset(size.width * 0.53, size.height * 0.36),
      name: 'AG-DMS Metro Station',
      icon: Icons.subway_rounded,
      color: AppColors.cyan,
    );

    _drawLandmark(
      canvas,
      pos: Offset(size.width * 0.44, size.height * 0.58),
      name: 'Teynampet Signal',
      icon: Icons.traffic_rounded,
      color: AppColors.warningAmber,
    );

    _drawLandmark(
      canvas,
      pos: Offset(size.width * 0.65, size.height * 0.28),
      name: 'Semmozhi Poonga (Botanical Garden)',
      icon: Icons.park_rounded,
      color: AppColors.successGreen,
    );

    // 9. Current User Location at Anna Salai, Teynampet
    final userPos = Offset(size.width * 0.50, size.height * 0.50);

    // 12m Accuracy radius zone (pulsing cyan circle)
    final accuracyFill = Paint()
      ..color = AppColors.cyan.withOpacity(0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userPos, 48, accuracyFill);

    final accuracyStroke = Paint()
      ..color = AppColors.cyan.withOpacity(0.55)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(userPos, 48, accuracyStroke);

    // Inner radar ring
    canvas.drawCircle(userPos, 28, accuracyStroke..color = AppColors.cyan.withOpacity(0.3));

    // Blue glow halo
    final haloPaint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userPos, 16, haloPaint);

    // Solid blue location pin
    final pinPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userPos, 10, pinPaint);

    // White precision dot in center
    final whiteDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userPos, 3.5, whiteDot);

    // "You are here" label badge above pin
    final textSpan = TextSpan(
      text: 'You are here (12m)',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        backgroundColor: Color(0xCC0052CC),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(userPos.dx - (textPainter.width / 2), userPos.dy - 32));
  }

  void _drawLandmark(
    Canvas canvas, {
    required Offset pos,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    // Landmark circle
    final paint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 10, paint);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, 10, stroke);

    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 3.5, dot);

    // Landmark text label
    final span = TextSpan(
      text: name,
      style: TextStyle(
        color: Colors.white.withOpacity(0.85),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(color: Colors.black, blurRadius: 4),
        ],
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(pos.dx + 14, pos.dy - 6));
  }

  @override
  bool shouldRepaint(covariant _GoogleMapFullInteractivePainter oldDelegate) {
    return oldDelegate.style != style;
  }
}
