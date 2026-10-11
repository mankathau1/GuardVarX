import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencyPermissionsState {
  final bool camera;
  final bool microphone;
  final bool location;
  final bool bluetooth;
  final bool nearbyWifi;
  final bool notification;
  final bool isChecking;

  const EmergencyPermissionsState({
    this.camera = false,
    this.microphone = false,
    this.location = false,
    this.bluetooth = false,
    this.nearbyWifi = false,
    this.notification = false,
    this.isChecking = false,
  });

  bool get allGranted =>
      camera && microphone && location && bluetooth && nearbyWifi && notification;

  int get grantedCount {
    int count = 0;
    if (camera) count++;
    if (microphone) count++;
    if (location) count++;
    if (bluetooth) count++;
    if (nearbyWifi) count++;
    if (notification) count++;
    return count;
  }

  EmergencyPermissionsState copyWith({
    bool? camera,
    bool? microphone,
    bool? location,
    bool? bluetooth,
    bool? nearbyWifi,
    bool? notification,
    bool? isChecking,
  }) {
    return EmergencyPermissionsState(
      camera: camera ?? this.camera,
      microphone: microphone ?? this.microphone,
      location: location ?? this.location,
      bluetooth: bluetooth ?? this.bluetooth,
      nearbyWifi: nearbyWifi ?? this.nearbyWifi,
      notification: notification ?? this.notification,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class EmergencyPermissionsNotifier extends StateNotifier<EmergencyPermissionsState> {
  EmergencyPermissionsNotifier() : super(const EmergencyPermissionsState()) {
    checkAllPermissions();
  }

  Future<void> checkAllPermissions() async {
    state = state.copyWith(isChecking: true);
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      final locStatus = await Permission.location.status;
      final btScanStatus = await Permission.bluetoothScan.status;
      final wifiStatus = await Permission.nearbyWifiDevices.status;
      final notifStatus = await Permission.notification.status;

      state = state.copyWith(
        camera: cameraStatus.isGranted,
        microphone: micStatus.isGranted,
        location: locStatus.isGranted,
        bluetooth: btScanStatus.isGranted,
        nearbyWifi: wifiStatus.isGranted,
        notification: notifStatus.isGranted,
        isChecking: false,
      );
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      state = state.copyWith(isChecking: false);
    }
  }

  Future<bool> requestAllEmergencyPermissions() async {
    state = state.copyWith(isChecking: true);
    try {
      // 1. Camera
      final cam = await Permission.camera.request();
      // 2. Microphone
      final mic = await Permission.microphone.request();
      // 3. Location
      final loc = await Permission.location.request();
      // 4. Bluetooth permissions (Scan, Advertise, Connect)
      final btScan = await Permission.bluetoothScan.request();
      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothConnect.request();
      // 5. Nearby Wi-Fi devices
      final wifi = await Permission.nearbyWifiDevices.request();
      // 6. Notifications
      final notif = await Permission.notification.request();

      final newState = state.copyWith(
        camera: cam.isGranted,
        microphone: mic.isGranted,
        location: loc.isGranted,
        bluetooth: btScan.isGranted,
        nearbyWifi: wifi.isGranted,
        notification: notif.isGranted,
        isChecking: false,
      );
      state = newState;
      return newState.allGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      state = state.copyWith(isChecking: false);
      return false;
    }
  }
}

final emergencyPermissionsProvider =
    StateNotifierProvider<EmergencyPermissionsNotifier, EmergencyPermissionsState>((ref) {
  return EmergencyPermissionsNotifier();
});
