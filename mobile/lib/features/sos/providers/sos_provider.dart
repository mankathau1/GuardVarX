import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/native/connectivity_channel.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/offline_store.dart';
import '../domain/emergency_model.dart';
import '../../auth/providers/auth_provider.dart';

class SosNotifier extends StateNotifier<EmergencyIncident?> {
  final ApiClient apiClient;

  SosNotifier(this.apiClient) : super(null);

  Future<void> triggerSOS({
    required EmergencyType type,
    String? message,
    double latitude = 28.5355,
    double longitude = 77.3910,
    double accuracy = 8.0,
  }) async {
    final incidentId = 'inc_${const Uuid().v4()}';
    final now = DateTime.now().toUtc();

    var incident = EmergencyIncident(
      incidentId: incidentId,
      emergencyType: type,
      message: message,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy,
      locationTimestamp: now,
      status: DeliveryStatus.created,
    );

    state = incident;

    // STEP 1: Mandatory Offline Persistence BEFORE Network
    await OfflineStore.saveIncident(LocalIncident(
      incidentId: incidentId,
      emergencyType: type.name,
      message: message,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: now.toIso8601String(),
      deliveryStatus: DeliveryStatus.localSaved.name,
    ));

    incident = incident.copyWith(status: DeliveryStatus.localSaved);
    state = incident;

    // STEP 2: Initiate Background BLE Mesh Broadcast
    await NativeConnectivityChannel.startBleAdvertising(
      incidentId: incidentId,
      emergencyType: type.name,
      latitude: latitude,
      longitude: longitude,
    );

    // STEP 3: Attempt Network Ingestion
    incident = incident.copyWith(status: DeliveryStatus.sending);
    state = incident;

    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.emergencies,
        data: {
          'incident_id': incidentId,
          'emergency_type': type.name,
          'message': message,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy_meters': accuracy,
          'location_timestamp': now.toIso8601String(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final receiptId = data['receipt_id'] as String?;
      final notifiedCount = data['contacts_notified_count'] as int? ?? 0;

      incident = incident.copyWith(
        status: DeliveryStatus.serverReceived,
        receiptId: receiptId,
        contactsNotifiedCount: notifiedCount,
      );
      state = incident;

      await OfflineStore.updateIncidentStatus(incidentId, DeliveryStatus.serverReceived.name, isSynced: true);
    } catch (_) {
      // Network failed or offline: Honest status representation
      incident = incident.copyWith(status: DeliveryStatus.relaying);
      state = incident;

      await OfflineStore.enqueueOutbox(ApiEndpoints.emergencies, 'POST', {
        'incident_id': incidentId,
        'emergency_type': type.name,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
      });
    }
  }

  Future<void> cancelSOS(String reason, {String pin = ''}) async {
    if (state == null) return;
    final id = state!.incidentId;

    await NativeConnectivityChannel.stopBleAdvertising();

    try {
      await apiClient.dio.post(
        ApiEndpoints.emergencyCancel(id),
        data: {'reason': reason, 'pin': pin},
      );
    } catch (_) {}

    await OfflineStore.updateIncidentStatus(id, DeliveryStatus.cancelled.name);
    state = state!.copyWith(status: DeliveryStatus.cancelled);
  }

  Future<void> resolveSOS() async {
    if (state == null) return;
    final id = state!.incidentId;

    await NativeConnectivityChannel.stopBleAdvertising();

    try {
      await apiClient.dio.post(ApiEndpoints.emergencyResolve(id));
    } catch (_) {}

    await OfflineStore.updateIncidentStatus(id, DeliveryStatus.resolved.name);
    state = state!.copyWith(status: DeliveryStatus.resolved);
  }

  void reset() {
    state = null;
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, EmergencyIncident?>((ref) {
  final client = ref.watch(apiClientProvider);
  return SosNotifier(client);
});
