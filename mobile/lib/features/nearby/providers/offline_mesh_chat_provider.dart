import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/native/connectivity_channel.dart';
import '../../../core/native/wifi_lan_mesh_service.dart';
import '../../../core/providers/live_location_provider.dart';

class OfflineMeshChatState {
  final Map<String, List<WifiLanMessage>> conversations;
  final bool isLanServerRunning;
  final String statusMessage;

  const OfflineMeshChatState({
    this.conversations = const {},
    this.isLanServerRunning = false,
    this.statusMessage = 'Offline LAN & BLE Mesh Ready',
  });

  OfflineMeshChatState copyWith({
    Map<String, List<WifiLanMessage>>? conversations,
    bool? isLanServerRunning,
    String? statusMessage,
  }) {
    return OfflineMeshChatState(
      conversations: conversations ?? this.conversations,
      isLanServerRunning: isLanServerRunning ?? this.isLanServerRunning,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class OfflineMeshChatNotifier extends StateNotifier<OfflineMeshChatState> {
  final Ref ref;
  final WifiLanMeshService _lanService = WifiLanMeshService();
  StreamSubscription? _lanStreamSub;

  OfflineMeshChatNotifier(this.ref) : super(const OfflineMeshChatState()) {
    _startLanListener();
  }

  Future<void> _startLanListener() async {
    final started = await _lanService.startServer();
    state = state.copyWith(isLanServerRunning: started);

    _lanStreamSub?.cancel();
    _lanStreamSub = _lanService.messageStream.listen((msg) {
      _receiveIncomingMessage(msg);
    });
  }

  void _receiveIncomingMessage(WifiLanMessage msg) {
    HapticFeedback.selectionClick();
    final map = Map<String, List<WifiLanMessage>>.from(state.conversations);
    final key = msg.senderId;
    final currentList = map[key] ?? [];
    map[key] = [...currentList, msg];

    state = state.copyWith(
      conversations: map,
      statusMessage: '📩 Offline message received from ${msg.senderName} (${msg.channel})',
    );
  }

  /// Send offline message over Both Same Wi-Fi LAN UDP broadcast AND Bluetooth mesh
  Future<void> sendMessage({
    required String peerId,
    required String peerName,
    required String text,
    bool isEmergency = false,
  }) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();

    final liveLoc = ref.read(liveLocationProvider);
    final myMessage = WifiLanMessage(
      id: 'mesh_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      senderName: 'You',
      recipientId: peerId,
      text: text.trim(),
      timestamp: DateTime.now(),
      channel: 'WIFI_LAN_UDP & BLE',
      isEmergency: isEmergency,
    );

    // 1. Add to local conversation
    final map = Map<String, List<WifiLanMessage>>.from(state.conversations);
    final currentList = map[peerId] ?? [];
    map[peerId] = [...currentList, myMessage];

    state = state.copyWith(
      conversations: map,
      statusMessage: 'Transmitting offline packet...',
    );

    // 2. Broadcast over Same Wi-Fi UDP port 58888
    await _lanService.broadcastMessage(myMessage);

    // 3. Also transmit over Bluetooth Low Energy Burst
    await NativeConnectivityChannel.sendBleHelpRequest(
      peerId: peerId,
      message: text.trim(),
      latitude: liveLoc.latitude,
      longitude: liveLoc.longitude,
    );

    state = state.copyWith(
      statusMessage: '✅ Delivered via Same Wi-Fi LAN (UDP 58888) & Bluetooth Mesh',
    );
  }

  List<WifiLanMessage> getMessagesForPeer(String peerId) {
    return state.conversations[peerId] ?? [];
  }

  @override
  void dispose() {
    _lanStreamSub?.cancel();
    _lanService.stop();
    super.dispose();
  }
}

final offlineMeshChatProvider =
    StateNotifierProvider<OfflineMeshChatNotifier, OfflineMeshChatState>((ref) {
  return OfflineMeshChatNotifier(ref);
});
