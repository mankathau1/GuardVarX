import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/widgets/gradient_icon_box.dart';

class LocationCard extends StatelessWidget {
  final String address;
  final String cityState;
  final double accuracyMeters;
  final String freshness;
  final double latitude;
  final double longitude;
  final bool isPermissionGranted;
  final VoidCallback onDetailsTap;

  const LocationCard({
    super.key,
    this.address = 'Anna Salai, Teynampet',
    this.cityState = 'Chennai, Tamil Nadu',
    this.accuracyMeters = 12.0,
    this.freshness = '2 min ago',
    this.latitude = 13.040517,
    this.longitude = 80.250328,
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
      glowRadius: 14,
      borderRadius: 18.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          // Left: Address info & Location Pin
          Expanded(
            flex: 12,
            child: Row(
              children: [
                GradientIconBox(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.primaryBlue,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.18),
                  borderColor: AppColors.primaryBlue.withOpacity(0.35),
                  size: 38,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Current Location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        cityState,
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
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.secondaryText,
                  size: 13,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right: Live Google Map Preview Viewport with Radar Rings & Accuracy Pill
          Expanded(
            flex: 10,
            child: SizedBox(
              height: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // A. Instant Dark Map Vector Ground Layer (Zero delay)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GoogleMapMiniPreviewPainter(),
                      ),
                    ),

                    // B. Live Raster Map Tiles (CartoDB Dark Matter)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.85,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(latitude, longitude),
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none, // Do not intercept Home scroll
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png',
                              userAgentPackageName: 'org.guardvarx.app',
                              tileBuilder: (context, tileWidget, tile) {
                                return tileWidget;
                              },
                            ),
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: LatLng(latitude, longitude),
                                  radius: 20,
                                  useRadiusInMeter: false,
                                  color: AppColors.cyan.withOpacity(0.18),
                                  borderColor: AppColors.cyan.withOpacity(0.5),
                                  borderStrokeWidth: 1.2,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(latitude, longitude),
                                  width: 20,
                                  height: 20,
                                  child: Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryBlue.withOpacity(0.8),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // C. Interactive Navigation Chevrons (< and >)
                    Positioned(
                      left: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),

                    // D. Accuracy Glass Badge Pill (e.g. 12 m)
                    Positioned(
                      right: 12,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xF009121D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan.withOpacity(0.4), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${accuracyMeters.toStringAsFixed(0)} m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a dark-mode street map inspired by Google Maps
/// centered around Anna Salai / Teynampet, Chennai with concentric radar rings.
class _GoogleMapMiniPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Map Background
    final bgPaint = Paint()..color = const Color(0xFF0B1421);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Blocks / Buildings (Subtle polygons)
    final blockPaint = Paint()
      ..color = const Color(0xFF101C2E)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, 8, 28, 22), const Radius.circular(3)),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(50, 6, 32, 18), const Radius.circular(3)),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, 42, 34, 22), const Radius.circular(3)),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(52, 46, 36, 20), const Radius.circular(3)),
      blockPaint,
    );

    // 3. Minor Streets Grid
    final minorStreetPaint = Paint()
      ..color = const Color(0xFF17293F)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Horizontal minor lanes
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), minorStreetPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), minorStreetPaint);

    // Vertical minor lanes
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), minorStreetPaint);
    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(size.width * 0.8, size.height), minorStreetPaint);

    // 4. Secondary Crossing Road (Mount Road tributary)
    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFF1E3552)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.52), Offset(size.width, size.height * 0.48), secondaryRoadPaint);

    // 5. Main Arterial Road (Anna Salai - diagonal axis)
    final mainRoadPaint = Paint()
      ..color = const Color(0xFF274468)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.15, size.height), Offset(size.width * 0.75, 0), mainRoadPaint);

    // Main road inner center lane
    final lanePaint = Paint()
      ..color = const Color(0xFF38608F)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.15, size.height), Offset(size.width * 0.75, 0), lanePaint);

    // 6. User Location Center
    final center = Offset(size.width * 0.52, size.height * 0.48);

    // Concentric Radar Accuracy Rings (Google Maps blue accuracy radius)
    final outerRingPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24, outerRingPaint);

    final ringStrokePaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 24, ringStrokePaint);
    canvas.drawCircle(center, 14, ringStrokePaint..color = AppColors.cyan.withOpacity(0.25));

    // Outer glow for location marker
    final haloPaint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9, haloPaint);

    // Blue User Location Dot
    final dotPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.5, dotPaint);

    // White Center Core (Google Maps precision dot)
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
