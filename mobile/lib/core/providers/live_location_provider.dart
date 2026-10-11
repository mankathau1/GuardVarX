import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  LiveLocationNotifier()
      : super(LiveLocationState(lastUpdated: DateTime.now())) {
    initLiveLocation();
  }

  Future<void> initLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services disabled, retain fallback
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

      // Start continuous live stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3, // Update every 3 meters
        ),
      ).listen(
        _updatePosition,
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
