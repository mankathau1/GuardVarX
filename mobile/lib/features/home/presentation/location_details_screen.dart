import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

class LocationDetailsScreen extends StatefulWidget {
  const LocationDetailsScreen({super.key});

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  final MapController _mapController = MapController();
  String _mapStyle = 'Dark Standard';
  bool _isCopied = false;

  // Anna Salai, Teynampet, Chennai coordinates
  static const double _latitude = 13.040517;
  static const double _longitude = 80.250328;
  static const String _address = 'Anna Salai, Teynampet, Chennai, Tamil Nadu 600018';

  String get _tileUrl {
    switch (_mapStyle) {
      case 'Satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'Terrain':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      default:
        return 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png';
    }
  }

  void _recenter() {
    _mapController.move(const LatLng(_latitude, _longitude), 16.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surface,
        duration: Duration(seconds: 1),
        content: Text('Centered to Anna Salai, Teynampet', style: TextStyle(color: AppColors.cyan)),
      ),
    );
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
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
          // 1. Full-screen Live Interactive Map (FlutterMap + CartoDB Dark Tiles)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(_latitude, _longitude),
                initialZoom: 16.0,
                minZoom: 10.0,
                maxZoom: 19.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'org.guardvarx.app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: const LatLng(_latitude, _longitude),
                      radius: 36,
                      useRadiusInMeter: false,
                      color: AppColors.cyan.withOpacity(0.18),
                      borderColor: AppColors.cyan.withOpacity(0.65),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // A. Current User Pin
                    Marker(
                      point: const LatLng(_latitude, _longitude),
                      width: 140,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xE60052CC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                            ),
                            child: const Text(
                              'You are here (12m)',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: AppColors.cyan.withOpacity(0.8), blurRadius: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // B. AG-DMS Metro Station Marker
                    Marker(
                      point: const LatLng(13.0440, 80.2520),
                      width: 130,
                      height: 30,
                      child: Row(
                        children: [
                          const Icon(Icons.subway_rounded, color: AppColors.cyan, size: 16),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                            child: const Text('AG-DMS Metro', style: TextStyle(color: Colors.white, fontSize: 9)),
                          ),
                        ],
                      ),
                    ),

                    // C. Teynampet Signal Marker
                    Marker(
                      point: const LatLng(13.0375, 80.2485),
                      width: 130,
                      height: 30,
                      child: Row(
                        children: [
                          const Icon(Icons.traffic_rounded, color: AppColors.warningAmber, size: 16),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Teynampet Signal', style: TextStyle(color: Colors.white, fontSize: 9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
