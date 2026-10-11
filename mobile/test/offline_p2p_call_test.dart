import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/emergency_permission_service.dart';
import 'package:mobile/features/nearby/providers/offline_p2p_call_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmergencyPermissionsState tests', () {
    test('Calculates granted count accurately', () {
      const state = EmergencyPermissionsState(
        camera: true,
        microphone: true,
        location: true,
        bluetooth: false,
        nearbyWifi: false,
        notification: true,
      );

      expect(state.grantedCount, 4);
      expect(state.allGranted, false);

      final fullState = state.copyWith(bluetooth: true, nearbyWifi: true);
      expect(fullState.grantedCount, 6);
      expect(fullState.allGranted, true);
    });
  });

  group('OfflineP2PCallState tests', () {
    test('Formatted duration formats minutes and seconds correctly', () {
      const call = OfflineP2PCallState(
        durationSeconds: 125, // 2 mins 5 secs
      );
      expect(call.formattedDuration, '02:05');
    });

    test('Initializes in idle state and transitions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(offlineP2PCallProvider.notifier);
      final initial = container.read(offlineP2PCallProvider);
      expect(initial.status, OfflineCallStatus.idle);

      notifier.toggleMute();
      expect(container.read(offlineP2PCallProvider).isMuted, true);

      notifier.toggleSpeaker();
      expect(container.read(offlineP2PCallProvider).isSpeakerOn, false);

      notifier.setPushToTalk(true);
      expect(container.read(offlineP2PCallProvider).isPushToTalkActive, true);
    });
  });
}
