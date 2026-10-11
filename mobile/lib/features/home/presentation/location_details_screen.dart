import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as osm_map;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/live_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

const String _googleMapsApiKey = 'AIzaSyBF0d4p4BgfodP-TsqCJJBoqXZqcUQOE6k';

const String _googleDarkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0d1b2a"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a1a1a"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#00f0ff"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6bc5d2"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#122336"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1a2c3f"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#0b1522"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#243e5c"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#142d4c"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#061320"}]}
]
''';

enum MapEngine { googleMaps, offlineSatellite }

/// Real registered places from Google Maps / OpenStreetMap
class EmergencyPlace {
  final String id;
  final String name;
  final String type; // Police, Hospital, BusStop, Fire
  final double latitude;
  final double longitude;
  final String phone;
  final String address;
  final Color color;
  final IconData icon;
  final String badgeText;

  const EmergencyPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.address,
    required this.color,
    required this.icon,
    required this.badgeText,
  });
}

// Verified real fallback spots near the user's district (Thittakudi / Avinangudi / Cuddalore)
// in case device is offline or before network response arrives.
const List<EmergencyPlace> _verifiedInitialPlaces = [
  EmergencyPlace(
    id: 'init_police_1',
    name: 'Tittagudi Police Station',
    type: 'Police',
    latitude: 11.4015105,
    longitude: 79.122043,
    phone: '100',
    address: 'C42C+JR3, Vasishtapuram, Tamil Nadu 606106',
    color: Color(0xFF0088FF),
    icon: Icons.local_police_rounded,
    badgeText: 'POLICE',
  ),
  EmergencyPlace(
    id: 'init_police_2',
    name: 'DSP Office Tittagudi',
    type: 'Police',
    latitude: 11.4042758,
    longitude: 79.1108902,
    phone: '100',
    address: 'C436+P96, Ilamangalam, Tamil Nadu 606106',
    color: Color(0xFF0088FF),
    icon: Icons.local_police_rounded,
    badgeText: 'POLICE',
  ),
  EmergencyPlace(
    id: 'init_police_3',
    name: 'Pennadam Police Station',
    type: 'Police',
    latitude: 11.4012982,
    longitude: 79.2383562,
    phone: '100',
    address: 'C62Q+G89, Pennadam, Tamil Nadu 606105',
    color: Color(0xFF0088FF),
    icon: Icons.local_police_rounded,
    badgeText: 'POLICE',
  ),
  EmergencyPlace(
    id: 'init_hospital_1',
    name: 'Government Hospital Thittakudi',
    type: 'Hospital',
    latitude: 11.4014147,
    longitude: 79.1227126,
    phone: '108',
    address: 'Main Rd, beside Police Station, Vasishtapuram, Tamil Nadu 606106',
    color: Color(0xFFFF2A55),
    icon: Icons.local_hospital_rounded,
    badgeText: 'HOSPITAL',
  ),
  EmergencyPlace(
    id: 'init_hospital_2',
    name: 'J M HOSPITAL',
    type: 'Hospital',
    latitude: 11.4018113,
    longitude: 79.1224103,
    phone: '108',
    address: 'SH 141, Vasishtapuram, Tamil Nadu 606106',
    color: Color(0xFFFF2A55),
    icon: Icons.local_hospital_rounded,
    badgeText: 'HOSPITAL',
  ),
  EmergencyPlace(
    id: 'init_hospital_3',
    name: 'Madhura Hospitals',
    type: 'Hospital',
    latitude: 11.3991783,
    longitude: 79.1301926,
    phone: '108',
    address: 'Opp. EB office, Tittakudi, Dharmakudikkadu, Tamil Nadu 606106',
    color: Color(0xFFFF2A55),
    icon: Icons.local_hospital_rounded,
    badgeText: 'HOSPITAL',
  ),
  EmergencyPlace(
    id: 'init_transit_1',
    name: 'Pennadam Railway Station',
    type: 'BusStop',
    latitude: 11.3985165,
    longitude: 79.2209249,
    phone: '139',
    address: 'Eraiyur, Pe.Ponneri, Tamil Nadu 606111',
    color: Color(0xFF00F0FF),
    icon: Icons.directions_bus_rounded,
    badgeText: 'BUS STOP / TRANSIT',
  ),
  EmergencyPlace(
    id: 'init_transit_2',
    name: 'Ichchangadu Transit Halt',
    type: 'BusStop',
    latitude: 11.37065,
    longitude: 79.21937,
    phone: '1091',
    address: 'Thalavoi North, Tamil Nadu 621730',
    color: Color(0xFF00F0FF),
    icon: Icons.directions_bus_rounded,
    badgeText: 'BUS STOP / TRANSIT',
  ),
];

class LocationDetailsScreen extends ConsumerStatefulWidget {
  const LocationDetailsScreen({super.key});

  @override
  ConsumerState<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends ConsumerState<LocationDetailsScreen> {
  gmaps.GoogleMapController? _googleMapController;
  final osm_map.MapController _osmController = osm_map.MapController();

  MapEngine _engine = MapEngine.googleMaps;
  gmaps.MapType _googleMapType = gmaps.MapType.normal;
  bool _isDarkStyle = true;
  bool _trafficEnabled = true;
  String _activeCategoryFilter = 'All';
  EmergencyPlace? _selectedPlace;
  bool _isCopied = false;

  List<EmergencyPlace> _realPlaces = List.from(_verifiedInitialPlaces);
  bool _isLoadingPlaces = false;
  double? _lastFetchedLat;
  double? _lastFetchedLng;

  final Map<String, gmaps.BitmapDescriptor> _customIcons = {};

  @override
  void initState() {
    super.initState();
    _initCustomMarkerIcons();
  }

  Future<void> _initCustomMarkerIcons() async {
    try {
      final police = await _createBadgeMarker(
        label: 'POLICE 🚓',
        color: const Color(0xFF0088FF),
      );
      final hospital = await _createBadgeMarker(
        label: 'HOSPITAL 🏥',
        color: const Color(0xFFFF2A55),
      );
      final busStop = await _createBadgeMarker(
        label: 'BUS STOP 🚌',
        color: const Color(0xFF00F0FF),
      );
      final fire = await _createBadgeMarker(
        label: 'FIRE 🚒',
        color: const Color(0xFFFF8800),
      );

      if (mounted) {
        setState(() {
          _customIcons['Police'] = police;
          _customIcons['Hospital'] = hospital;
          _customIcons['BusStop'] = busStop;
          _customIcons['Fire'] = fire;
        });
      }
    } catch (_) {}
  }

  Future<gmaps.BitmapDescriptor> _createBadgeMarker({
    required String label,
    required Color color,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 170.0;
    const double height = 64.0;

    final RRect rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height - 14),
      const Radius.circular(14),
    );

    final Paint shadowPaint = Paint()
      ..color = color.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rrect, shadowPaint);

    final Paint fillPaint = Paint()..color = const Color(0xF5081423);
    canvas.drawRRect(rrect, fillPaint);

    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawRRect(rrect, borderPaint);

    final Path pointer = Path();
    pointer.moveTo(width / 2 - 10, height - 14);
    pointer.lineTo(width / 2, height);
    pointer.lineTo(width / 2 + 10, height - 14);
    pointer.close();

    canvas.drawPath(pointer, Paint()..color = const Color(0xF5081423));
    canvas.drawPath(pointer, borderPaint);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - 14 - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();
    return gmaps.BitmapDescriptor.fromBytes(bytes);
  }

  /// Live query to Google Places API (New) for real registered places around the user's GPS
  Future<void> _fetchRealGooglePlaces(double userLat, double userLng) async {
    if (_isLoadingPlaces) return;
    setState(() => _isLoadingPlaces = true);

    try {
      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
      );
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('X-Goog-Api-Key', _googleMapsApiKey);
      req.headers.set(
        'X-Goog-FieldMask',
        'places.displayName,places.location,places.formattedAddress,places.types',
      );

      final payload = jsonEncode({
        'includedTypes': [
          'police',
          'hospital',
          'bus_stop',
          'bus_station',
          'transit_station',
          'train_station',
          'fire_station',
        ],
        'maxResultCount': 20,
        'locationRestriction': {
          'circle': {
            'center': {'latitude': userLat, 'longitude': userLng},
            'radius': 25000.0, // 25 km around user
          },
        },
      });

      req.write(payload);
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final respBody = await resp.transform(utf8.decoder).join();
        final data = jsonDecode(respBody) as Map<String, dynamic>;
        final rawPlaces = data['places'] as List<dynamic>? ?? [];

        final List<EmergencyPlace> fetched = [];
        int idx = 0;
        for (final p in rawPlaces) {
          final loc = p['location'] as Map<String, dynamic>?;
          if (loc == null) continue;
          final placeLat = (loc['latitude'] as num).toDouble();
          final placeLng = (loc['longitude'] as num).toDouble();
          final name = (p['displayName']?['text'] as String?) ?? 'Registered Place';
          final address = (p['formattedAddress'] as String?) ?? '';
          final types = List<String>.from(p['types'] ?? []);

          String type = 'Police';
          Color color = const Color(0xFF0088FF);
          IconData icon = Icons.local_police_rounded;
          String badge = 'POLICE';
          String phone = '100';

          if (types.contains('police')) {
            type = 'Police';
            color = const Color(0xFF0088FF);
            icon = Icons.local_police_rounded;
            badge = 'POLICE';
            phone = '100';
          } else if (types.contains('hospital') || types.contains('health')) {
            type = 'Hospital';
            color = const Color(0xFFFF2A55);
            icon = Icons.local_hospital_rounded;
            badge = 'HOSPITAL';
            phone = '108';
          } else if (types.contains('fire_station')) {
            type = 'Fire';
            color = const Color(0xFFFF8800);
            icon = Icons.fire_truck_rounded;
            badge = 'FIRE';
            phone = '101';
          } else {
            type = 'BusStop';
            color = const Color(0xFF00F0FF);
            icon = Icons.directions_bus_rounded;
            badge = 'BUS STOP';
            phone = '1091';
          }

          fetched.add(
            EmergencyPlace(
              id: 'real_google_place_${idx++}',
              name: name,
              type: type,
              latitude: placeLat,
              longitude: placeLng,
              phone: phone,
              address: address,
              color: color,
              icon: icon,
              badgeText: badge,
            ),
          );
        }

        if (mounted && fetched.isNotEmpty) {
          setState(() {
            _realPlaces = fetched;
            _lastFetchedLat = userLat;
            _lastFetchedLng = userLng;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching real Google places: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  void _onGoogleMapCreated(gmaps.GoogleMapController controller) {
    _googleMapController = controller;
    if (_isDarkStyle && _googleMapType == gmaps.MapType.normal) {
      _applyDarkStyle();
    }
  }

  void _applyDarkStyle() {
    try {
      _googleMapController?.setMapStyle(_isDarkStyle ? _googleDarkMapStyle : null);
    } catch (_) {}
  }

  void _toggleTraffic() {
    setState(() {
      _trafficEnabled = !_trafficEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 1),
        content: Text(
          _trafficEnabled ? 'Live Google Traffic layer enabled' : 'Traffic layer hidden',
          style: const TextStyle(color: AppColors.cyan),
        ),
      ),
    );
  }

  void _fitCameraToBounds(List<gmaps.LatLng> points) {
    if (_googleMapController == null || points.isEmpty) return;

    if (points.length == 1) {
      _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(points.first, 15.5),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final pt in points) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    if ((maxLat - minLat).abs() < 0.002 && (maxLng - minLng).abs() < 0.002) {
      _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
          15.5,
        ),
      );
      return;
    }

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );

    _googleMapController!.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 80.0),
    );
  }

  void _filterCategory(String category, double userLat, double userLng) {
    setState(() {
      _activeCategoryFilter = category;
      _selectedPlace = null;
    });

    if (_googleMapController != null) {
      if (category == 'All') {
        // Zoom out smoothly to frame the entire district and all places + user GPS
        final allPoints = <gmaps.LatLng>[
          gmaps.LatLng(userLat, userLng),
          ..._realPlaces.map((p) => gmaps.LatLng(p.latitude, p.longitude)),
        ];
        _fitCameraToBounds(allPoints);
      } else {
        // Automatically fly camera directly to where the selected category places are
        final matching = _realPlaces.where((p) => p.type == category).toList();
        if (matching.isNotEmpty) {
          final points = matching.map((p) => gmaps.LatLng(p.latitude, p.longitude)).toList();
          _fitCameraToBounds(points);
        }
      }
    }
  }

  void _recenter(double lat, double lng, String address) {
    if (_engine == MapEngine.googleMaps && _googleMapController != null) {
      _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(target: gmaps.LatLng(lat, lng), zoom: 15.0),
        ),
      );
    } else {
      _osmController.move(osm.LatLng(lat, lng), 15.0);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 1),
        content: Text('Centered to $address', style: const TextStyle(color: AppColors.cyan)),
      ),
    );
  }

  String _formatDistance(double userLat, double userLng, double placeLat, double placeLng) {
    final dist = Geolocator.distanceBetween(userLat, userLng, placeLat, placeLng);
    if (dist < 1000) {
      return '${dist.toStringAsFixed(0)} m away';
    } else {
      return '${(dist / 1000).toStringAsFixed(1)} km away';
    }
  }

  Set<gmaps.Marker> _buildGoogleMarkers(double userLat, double userLng) {
    final markers = <gmaps.Marker>{};

    for (final place in _realPlaces) {
      if (_activeCategoryFilter != 'All' && place.type != _activeCategoryFilter) {
        continue;
      }

      final distanceStr = _formatDistance(userLat, userLng, place.latitude, place.longitude);

      gmaps.BitmapDescriptor iconDescriptor;
      if (_customIcons.containsKey(place.type)) {
        iconDescriptor = _customIcons[place.type]!;
      } else {
        double hue = gmaps.BitmapDescriptor.hueCyan;
        if (place.type == 'Police') hue = gmaps.BitmapDescriptor.hueAzure;
        if (place.type == 'Hospital') hue = gmaps.BitmapDescriptor.hueRed;
        if (place.type == 'Fire') hue = gmaps.BitmapDescriptor.hueOrange;
        iconDescriptor = gmaps.BitmapDescriptor.defaultMarkerWithHue(hue);
      }

      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(place.id),
          position: gmaps.LatLng(place.latitude, place.longitude),
          icon: iconDescriptor,
          infoWindow: gmaps.InfoWindow(
            title: '${place.name} ($distanceStr)',
            snippet: place.address,
          ),
          onTap: () {
            setState(() => _selectedPlace = place);
            if (_googleMapController != null) {
              _googleMapController!.animateCamera(
                gmaps.CameraUpdate.newLatLngZoom(
                  gmaps.LatLng(place.latitude, place.longitude),
                  16.0,
                ),
              );
            }
          },
        ),
      );
    }

    return markers;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open dialer for $phoneNumber')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $phoneNumber...')),
        );
      }
    }
  }

  Future<void> _launchGoogleMapsDirections(double lat, double lng, String label) async {
    final navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        content: Text('Coordinates copied: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}', style: const TextStyle(color: AppColors.successGreen)),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _shareLocation(double lat, double lng, String address) async {
    final googleMapsLink = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final shareMessage = '''🚨 My Live GPS Location (GuardVarX Safety):
📍 $address
🌐 Coordinates: ${lat.toStringAsFixed(5)}° N, ${lng.toStringAsFixed(5)}° E
🗺️ Open in Google Maps: $googleMapsLink''';

    try {
      await Share.share(
        shareMessage,
        subject: '🚨 Live GPS Location - GuardVarX',
      );
    } catch (_) {
      Clipboard.setData(ClipboardData(text: shareMessage));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            duration: Duration(seconds: 2),
            content: Text('Live location link copied to clipboard', style: TextStyle(color: AppColors.cyan)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveLoc = ref.watch(liveLocationProvider);
    final lat = liveLoc.latitude;
    final lng = liveLoc.longitude;
    final address = liveLoc.address;
    final cityState = liveLoc.cityState;
    final accuracy = liveLoc.accuracy;

    // Fetch real Google Places whenever GPS moves or initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastFetchedLat == null ||
          Geolocator.distanceBetween(_lastFetchedLat!, _lastFetchedLng!, lat, lng) > 500) {
        _fetchRealGooglePlaces(lat, lng);
      }
    });

    final policeCount = _realPlaces.where((p) => p.type == 'Police').length;
    final hospitalCount = _realPlaces.where((p) => p.type == 'Hospital').length;
    final busStopCount = _realPlaces.where((p) => p.type == 'BusStop').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Map Viewport (Official Google Maps SDK OR High-Res Esri Backup)
          Positioned.fill(
            child: _engine == MapEngine.googleMaps
                ? gmaps.GoogleMap(
                    onMapCreated: _onGoogleMapCreated,
                    initialCameraPosition: gmaps.CameraPosition(
                      target: gmaps.LatLng(lat, lng),
                      zoom: 14.5,
                    ),
                    myLocationEnabled: true, // Official Google pulsing Blue GPS Dot
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    trafficEnabled: _trafficEnabled, // Real-time Google Live Traffic
                    mapType: _googleMapType,
                    markers: _buildGoogleMarkers(lat, lng),
                  )
                : osm_map.FlutterMap(
                    mapController: _osmController,
                    options: osm_map.MapOptions(
                      initialCenter: osm.LatLng(lat, lng),
                      initialZoom: 15.0,
                    ),
                    children: [
                      osm_map.TileLayer(
                        urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'org.guardvarx.app',
                      ),
                      osm_map.CircleLayer(
                        circles: [
                          osm_map.CircleMarker(
                            point: osm.LatLng(lat, lng),
                            radius: 36,
                            useRadiusInMeter: false,
                            color: AppColors.cyan.withOpacity(0.18),
                            borderColor: AppColors.cyan.withOpacity(0.65),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          // 2. Top Bar (Back button, Title, Filter Chips)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xEB08121E),
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

                        // Title Pill with Live Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xEB08121E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isLoadingPlaces ? const Color(0xFFFFB300) : const Color(0xFF00FF88),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLoadingPlaces ? 'Updating Real Places...' : 'Google Maps • Real Places',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Map Style & Layer Switcher Popup
                        PopupMenuButton<String>(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.glassBorder),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xEB08121E),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: const Icon(
                              Icons.layers_rounded,
                              color: AppColors.cyan,
                              size: 18,
                            ),
                          ),
                          onSelected: (val) {
                            if (val == 'traffic') {
                              _toggleTraffic();
                            } else if (val == 'refresh_places') {
                              _fetchRealGooglePlaces(lat, lng);
                            } else if (val == 'engine_toggle') {
                              setState(() {
                                _engine = _engine == MapEngine.googleMaps
                                    ? MapEngine.offlineSatellite
                                    : MapEngine.googleMaps;
                              });
                            } else if (val == 'dark') {
                              setState(() {
                                _googleMapType = gmaps.MapType.normal;
                                _isDarkStyle = true;
                              });
                              _applyDarkStyle();
                            } else if (val == 'normal') {
                              setState(() {
                                _googleMapType = gmaps.MapType.normal;
                                _isDarkStyle = false;
                              });
                              try {
                                _googleMapController?.setMapStyle(null);
                              } catch (_) {}
                            } else if (val == 'satellite') {
                              setState(() => _googleMapType = gmaps.MapType.satellite);
                            } else if (val == 'terrain') {
                              setState(() => _googleMapType = gmaps.MapType.terrain);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'dark',
                              child: Row(
                                children: const [
                                  Icon(Icons.dark_mode_rounded, color: AppColors.cyan, size: 16),
                                  SizedBox(width: 10),
                                  Text('Cyber Dark Map', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'normal',
                              child: Row(
                                children: const [
                                  Icon(Icons.map_outlined, color: Colors.white70, size: 16),
                                  SizedBox(width: 10),
                                  Text('Standard Map', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'satellite',
                              child: Row(
                                children: const [
                                  Icon(Icons.satellite_alt_rounded, color: Colors.white70, size: 16),
                                  SizedBox(width: 10),
                                  Text('Satellite View', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'traffic',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.traffic_rounded,
                                    color: _trafficEnabled ? const Color(0xFF00FF88) : Colors.white38,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _trafficEnabled ? 'Traffic: ON' : 'Traffic: OFF',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'refresh_places',
                              child: Row(
                                children: const [
                                  Icon(Icons.refresh_rounded, color: AppColors.cyan, size: 16),
                                  SizedBox(width: 10),
                                  Text('Refresh Nearby Places', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'engine_toggle',
                              child: Row(
                                children: [
                                  const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBlue, size: 16),
                                  const SizedBox(width: 10),
                                  Text(
                                    _engine == MapEngine.googleMaps ? 'Switch to Backup Engine' : 'Switch to Google Maps',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Horizontal Category Filters: All, Police, Hospital, BusStop
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip('All', '🚨 All (${_realPlaces.length})', lat, lng, const Color(0xFF0088FF)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Police', '🚓 Police ($policeCount)', lat, lng, const Color(0xFF0088FF)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Hospital', '🏥 Hospital ($hospitalCount)', lat, lng, const Color(0xFFFF2A55)),
                        const SizedBox(width: 8),
                        _buildFilterChip('BusStop', '🚌 Bus Stop ($busStopCount)', lat, lng, const Color(0xFF00F0FF)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Right-side Map Controls
          Positioned(
            right: 16,
            bottom: _selectedPlace != null ? 315 : 225,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  iconColor: AppColors.cyan,
                  onTap: () => _recenter(lat, lng, address),
                  tooltip: 'Recenter GPS',
                ),
                const SizedBox(height: 10),
                _buildMapControlBtn(
                  icon: Icons.traffic_rounded,
                  iconColor: _trafficEnabled ? const Color(0xFF00FF88) : Colors.white60,
                  onTap: _toggleTraffic,
                  tooltip: 'Toggle Live Traffic',
                ),
                const SizedBox(height: 10),
                _buildMapControlBtn(
                  icon: Icons.refresh_rounded,
                  iconColor: _isLoadingPlaces ? const Color(0xFFFFB300) : Colors.white70,
                  onTap: () => _fetchRealGooglePlaces(lat, lng),
                  tooltip: 'Search Real Places',
                ),
              ],
            ),
          ),

          // 4. Selected Real Google Place Details Card (Appears when marker tapped)
          if (_selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 220,
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                backgroundColor: const Color(0xF506111E),
                borderColor: _selectedPlace!.color.withOpacity(0.6),
                glowColor: _selectedPlace!.color.withOpacity(0.35),
                glowRadius: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedPlace!.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: _selectedPlace!.color.withOpacity(0.5)),
                          ),
                          child: Icon(_selectedPlace!.icon, color: _selectedPlace!.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _selectedPlace!.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _selectedPlace!.color.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      _selectedPlace!.badgeText,
                                      style: TextStyle(
                                        color: _selectedPlace!.color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDistance(
                                      lat,
                                      lng,
                                      _selectedPlace!.latitude,
                                      _selectedPlace!.longitude,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.cyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selectedPlace!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedPlace!.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedPlace = null),
                          child: const Icon(Icons.close_rounded, color: AppColors.secondaryText, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPlace!.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                            ),
                            onPressed: () => _makePhoneCall(_selectedPlace!.phone),
                            icon: const Icon(Icons.call_rounded, size: 15),
                            label: Text(
                              'Emergency Call (${_selectedPlace!.phone})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.glassBorder),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _launchGoogleMapsDirections(
                              _selectedPlace!.latitude,
                              _selectedPlace!.longitude,
                              _selectedPlace!.name,
                            ),
                            icon: const Icon(Icons.navigation_rounded, size: 14, color: AppColors.cyan),
                            label: const Text(
                              'Directions',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 5. Bottom Live Location Status Card
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
                          children: [
                            Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cityState,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan.withOpacity(0.35)),
                        ),
                        child: Text(
                          '± ${accuracy.toStringAsFixed(0)} m GPS',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Coordinates row with copy button
                  GestureDetector(
                    onTap: () => _copyCoordinates(lat, lng),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedGlassSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded, color: AppColors.secondaryText, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
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

                  // Primary & Secondary Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          onPressed: () => _launchGoogleMapsDirections(lat, lng, address),
                          icon: const Icon(Icons.open_in_new_rounded, size: 15),
                          label: const Text(
                            'Open Google Maps App',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            side: const BorderSide(color: AppColors.cyan, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _shareLocation(lat, lng, address),
                          icon: const Icon(Icons.share_rounded, size: 14),
                          label: const Text(
                            'Share GPS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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

  Widget _buildFilterChip(String category, String title, double lat, double lng, Color themeColor) {
    final isSelected = _activeCategoryFilter == category;
    return GestureDetector(
      onTap: () => _filterCategory(category, lat, lng),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : const Color(0xEB0A1422),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white70 : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withOpacity(0.55),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
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
          width: 44,
          height: 44,
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
