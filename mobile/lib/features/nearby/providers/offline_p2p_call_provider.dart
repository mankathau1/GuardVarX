import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_mesh_chat_provider.dart';

enum OfflineCallStatus {
  idle,
  dialing,
  incoming,
  connected,
  ended,
}

enum OfflineCallType {
  audio,
  video,
}

class OfflinePhotoItem {
  final String id;
  final String senderName;
  final String path;
  final DateTime timestamp;
  final bool isMe;

  const OfflinePhotoItem({
    required this.id,
    required this.senderName,
    required this.path,
    required this.timestamp,
    required this.isMe,
  });
}

class OfflineP2PCallState {
  final OfflineCallStatus status;
  final OfflineCallType callType;
  final String peerId;
  final String peerName;
  final int durationSeconds;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoEnabled;
  final bool isFrontCamera;
  final bool isPushToTalkActive;
  final String connectionChannel;
  final int bitrateKbps;
  final int latencyMs;
  final List<OfflinePhotoItem> sharedPhotos;

  const OfflineP2PCallState({
    this.status = OfflineCallStatus.idle,
    this.callType = OfflineCallType.video,
    this.peerId = '',
    this.peerName = '',
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isVideoEnabled = true,
    this.isFrontCamera = true,
    this.isPushToTalkActive = false,
    this.connectionChannel = 'Wi-Fi Direct (5GHz) & BLE Mesh',
    this.bitrateKbps = 1850,
    this.latencyMs = 12,
    this.sharedPhotos = const [],
  });

  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  OfflineP2PCallState copyWith({
    OfflineCallStatus? status,
    OfflineCallType? callType,
    String? peerId,
    String? peerName,
    int? durationSeconds,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoEnabled,
    bool? isFrontCamera,
    bool? isPushToTalkActive,
    String? connectionChannel,
    int? bitrateKbps,
    int? latencyMs,
    List<OfflinePhotoItem>? sharedPhotos,
  }) {
    return OfflineP2PCallState(
      status: status ?? this.status,
      callType: callType ?? this.callType,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isPushToTalkActive: isPushToTalkActive ?? this.isPushToTalkActive,
      connectionChannel: connectionChannel ?? this.connectionChannel,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      latencyMs: latencyMs ?? this.latencyMs,
      sharedPhotos: sharedPhotos ?? this.sharedPhotos,
    );
  }
}

class OfflineP2PCallNotifier extends StateNotifier<OfflineP2PCallState> {
  final Ref ref;
  Timer? _durationTimer;
  Timer? _connectSimulationTimer;

  OfflineP2PCallNotifier(this.ref) : super(const OfflineP2PCallState());

  void startCall({
    required String peerId,
    required String peerName,
    required OfflineCallType type,
  }) {
    _durationTimer?.cancel();
    _connectSimulationTimer?.cancel();
    HapticFeedback.heavyImpact();

    state = state.copyWith(
      status: OfflineCallStatus.dialing,
      callType: type,
      peerId: peerId,
      peerName: peerName,
      durationSeconds: 0,
      isMuted: false,
      isSpeakerOn: true,
      isVideoEnabled: type == OfflineCallType.video,
      isFrontCamera: true,
    );

    // Broadcast call setup invitation packet over local Wi-Fi LAN & BLE
    ref.read(offlineMeshChatProvider.notifier).sendMessage(
      peerId: peerId,
      peerName: peerName,
      text: '📞 INCOMING_OFFLINE_${type.name.toUpperCase()}_CALL [P2P Direct WebRTC Link]',
      isEmergency: true,
    );

    // Auto-connect simulation after 2 seconds for smooth testability
    _connectSimulationTimer = Timer(const Duration(milliseconds: 2200), () {
      if (state.status == OfflineCallStatus.dialing) {
        state = state.copyWith(status: OfflineCallStatus.connected);
        HapticFeedback.mediumImpact();
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });
  }

  void toggleMute() {
    HapticFeedback.selectionClick();
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleSpeaker() {
    HapticFeedback.selectionClick();
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void toggleVideo() {
    HapticFeedback.selectionClick();
    state = state.copyWith(isVideoEnabled: !state.isVideoEnabled);
  }

  void switchCamera() {
    HapticFeedback.selectionClick();
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  void setPushToTalk(bool active) {
    if (active) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(isPushToTalkActive: active);
  }

  void endCall() {
    HapticFeedback.mediumImpact();
    _durationTimer?.cancel();
    _connectSimulationTimer?.cancel();
    state = state.copyWith(status: OfflineCallStatus.ended);

    // Reset back to idle after short delay
    Future.delayed(const Duration(milliseconds: 700), () {
      state = state.copyWith(status: OfflineCallStatus.idle, durationSeconds: 0);
    });
  }

  Future<void> sendOfflinePhoto({
    required String peerId,
    required String peerName,
    required String photoPath,
  }) async {
    HapticFeedback.mediumImpact();
    final newPhoto = OfflinePhotoItem(
      id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
      senderName: 'You',
      path: photoPath,
      timestamp: DateTime.now(),
      isMe: true,
    );

    final list = [...state.sharedPhotos, newPhoto];
    state = state.copyWith(sharedPhotos: list);

    // Broadcast file transfer token over mesh
    await ref.read(offlineMeshChatProvider.notifier).sendMessage(
      peerId: peerId,
      peerName: peerName,
      text: '📷 [OFFLINE PHOTO EVIDENCE ATTACHED] P2P Direct File Transfer Complete.',
      isEmergency: false,
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _connectSimulationTimer?.cancel();
    super.dispose();
  }
}

final offlineP2PCallProvider =
    StateNotifierProvider<OfflineP2PCallNotifier, OfflineP2PCallState>((ref) {
  return OfflineP2PCallNotifier(ref);
});
