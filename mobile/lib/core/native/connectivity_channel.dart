import 'package:flutter/services.dart';

class NativeConnectivityChannel {
  static const MethodChannel _channel = MethodChannel('com.guardvarx/connectivity');
  static const EventChannel _eventChannel = EventChannel('com.guardvarx/mesh_stream');

  /// Stream of relayed peer packets received over native BLE scan
  static Stream<dynamic> get relayedPacketsStream => _eventChannel.receiveBroadcastStream();

  /// Start BLE peripheral advertising for compact emergency packet
  static Future<bool> startBleAdvertising({
    required String incidentId,
    required String emergencyType,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('startBleAdvertising', {
        'incident_id': incidentId,
        'emergency_type': emergencyType,
        'latitude': latitude,
        'longitude': longitude,
      });
      return success ?? false;
    } on MissingPluginException {
      // Platform channel mock fallback for simulator / non-Android platforms
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stop BLE peripheral advertising
  static Future<void> stopBleAdvertising() async {
    try {
      await _channel.invokeMethod('stopBleAdvertising');
    } catch (_) {}
  }

  /// Start battery-aware BLE scanning for peer emergency mesh packets
  static Future<bool> startBleScanning() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('startBleScanning');
      return success ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stop BLE scanning
  static Future<void> stopBleScanning() async {
    try {
      await _channel.invokeMethod('stopBleScanning');
    } catch (_) {}
  }

  /// Trigger emergency loud siren audio
  static Future<void> triggerLoudSiren(bool enable) async {
    try {
      await _channel.invokeMethod('triggerLoudSiren', {'enable': enable});
    } catch (_) {}
  }

  /// Send fallback SMS to trusted contacts via native SMS Manager
  static Future<bool> sendFallbackSms(String phoneNumber, String message) async {
    try {
      final bool? sent = await _channel.invokeMethod<bool>('sendFallbackSms', {
        'phone': phoneNumber,
        'message': message,
      });
      return sent ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check hardware Bluetooth status
  static Future<bool> isBluetoothEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('isBluetoothEnabled');
      return enabled ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }
}
