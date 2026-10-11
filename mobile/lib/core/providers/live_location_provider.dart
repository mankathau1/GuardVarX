import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationState {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final String address;
  final String cityState;
  final bool hasPermission;
  final bool isGpsLive;
  final DateTime lastUpdated;

  const LiveLocationState({
    this.latitude = 13.040517,
    this.longitude = 80.250328,
    this.accuracy = 12.0,
    this.altitude = 14.0,
    this.speed = 0.0,
    this.address = 'Anna Salai, Teynampet',
    this.cityState = 'Chennai, Tamil Nadu',
    this.hasPermission = true,
    this.isGpsLive = false,
    required this.lastUpdated,
  });

  LiveLocationState copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    String? address,
    String? cityState,
    bool? hasPermission,
    bool? isGpsLive,
    DateTime? lastUpdated,
  }) {
    return LiveLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      address: address ?? this.address,
      cityState: cityState ?? this.cityState,
      hasPermission: hasPermission ?? this.hasPermission,
      isGpsLive: isGpsLive ?? this.isGpsLive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LiveLocationNotifier extends StateNotifier<LiveLocationState> {
  StreamSubscription<Position>? _positionSubscription;
  DateTime _lastGeocodeTime = DateTime.fromMillisecondsSinceEpoch(0);

  LiveLocationNotifier()
      : super(LiveLocationState(lastUpdated: DateTime.now())) {
    initLiveLocation();
  }

  Future<void> initLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(hasPermission: false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(hasPermission: false);
        return;
      }

      // Permission granted - get immediate fix
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      _updatePosition(initialPosition);
      _fetchRealAddress(initialPosition.latitude, initialPosition.longitude);

      // Start continuous live stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3, // Update every 3 meters
        ),
      ).listen(
        (pos) {
          _updatePosition(pos);
          // Throttle reverse geocoding to once every 20 seconds to save battery and network
          if (DateTime.now().difference(_lastGeocodeTime).inSeconds > 20) {
            _fetchRealAddress(pos.latitude, pos.longitude);
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      // Gracefully fall back to defaults on emulator or permission delay
    }
  }

  void _updatePosition(Position pos) {
    state = state.copyWith(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      speed: pos.speed,
      isGpsLive: true,
      hasPermission: true,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _fetchRealAddress(double lat, double lng) async {
    _lastGeocodeTime = DateTime.now();
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = p.street ?? p.name ?? '';
        final subLocality = p.subLocality ?? p.subAdministrativeArea ?? '';
        final locality = p.locality ?? p.subAdministrativeArea ?? '';
        final stateName = p.administrativeArea ?? '';
        final pin = p.postalCode ?? '';

        final addr = street.isNotEmpty
            ? (subLocality.isNotEmpty && subLocality != street ? '$street, $subLocality' : street)
            : (subLocality.isNotEmpty ? subLocality : locality);

        final city = locality.isNotEmpty
            ? (stateName.isNotEmpty ? '$locality, $stateName ${pin.isNotEmpty ? pin : ''}'.trim() : locality)
            : stateName;

        if (addr.isNotEmpty || city.isNotEmpty) {
          state = state.copyWith(
            address: addr.isNotEmpty ? addr : state.address,
            cityState: city.isNotEmpty ? city : state.cityState,
          );
        }
      }
    } catch (_) {
      // In offline mode, coordinates remain live
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final liveLocationProvider =
    StateNotifierProvider<LiveLocationNotifier, LiveLocationState>((ref) {
  return LiveLocationNotifier();
});
