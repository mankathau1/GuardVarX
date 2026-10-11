import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/native/wifi_lan_mesh_service.dart';

void main() {
  group('WifiLanMessage serialization tests', () {
    test('JSON serialization and deserialization retains fidelity', () {
      final now = DateTime.now();
      final msg = WifiLanMessage(
        id: 'mesh_test_101',
        senderId: 'device_alpha',
        senderName: 'Varathan',
        recipientId: 'device_beta',
        text: 'Emergency alert: Need nearby help offline',
        timestamp: now,
        channel: 'WIFI_LAN_UDP & BLE',
        isEmergency: true,
      );

      final json = msg.toJson();
      expect(json['id'], 'mesh_test_101');
      expect(json['senderId'], 'device_alpha');
      expect(json['text'], 'Emergency alert: Need nearby help offline');
      expect(json['isEmergency'], true);

      final reconstructed = WifiLanMessage.fromJson(json);
      expect(reconstructed.id, msg.id);
      expect(reconstructed.senderName, 'Varathan');
      expect(reconstructed.recipientId, 'device_beta');
      expect(reconstructed.text, msg.text);
      expect(reconstructed.channel, 'WIFI_LAN_UDP & BLE');
      expect(reconstructed.isEmergency, true);
    });

    test('WifiLanMessage handles missing optional values safely', () {
      final rawJson = {
        'id': 'mesh_fallback_1',
        'text': 'Ping test',
      };

      final parsed = WifiLanMessage.fromJson(rawJson);
      expect(parsed.id, 'mesh_fallback_1');
      expect(parsed.senderId, 'anonymous');
      expect(parsed.senderName, 'Nearby Peer');
      expect(parsed.recipientId, 'broadcast');
      expect(parsed.text, 'Ping test');
      expect(parsed.channel, 'WIFI_LAN_UDP');
      expect(parsed.isEmergency, false);
    });
  });
}
