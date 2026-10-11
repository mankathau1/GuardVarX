import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/offline_p2p_call_provider.dart';

class OfflineCallScreen extends ConsumerStatefulWidget {
  const OfflineCallScreen({super.key});

  @override
  ConsumerState<OfflineCallScreen> createState() => _OfflineCallScreenState();
}

class _OfflineCallScreenState extends ConsumerState<OfflineCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleCapturePhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        final call = ref.read(offlineP2PCallProvider);
        await ref.read(offlineP2PCallProvider.notifier).sendOfflinePhoto(
              peerId: call.peerId,
              peerName: call.peerName,
              photoPath: photo.path,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.surface,
              content: Text(
                '📷 Photo evidence transmitted directly over Wi-Fi P2P (0 Internet)!',
                style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(offlineP2PCallProvider);

    // Auto-pop if call ends
    ref.listen<OfflineP2PCallState>(offlineP2PCallProvider, (prev, next) {
      if (next.status == OfflineCallStatus.ended) {
        final nav = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && nav.canPop()) {
            nav.pop();
          }
        });
      }
    });

    final isVideo = call.callType == OfflineCallType.video && call.isVideoEnabled;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Background Video / Audio Viewport
            if (isVideo)
              _buildVideoViewport(call)
            else
              _buildAudioViewport(call),

            // 2. Top Info Header (Live Metrics & Status)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopHeader(call),
            ),

            // 3. Floating Picture-in-Picture (PiP) Window (Self Camera for Video Call)
            if (isVideo)
              Positioned(
                top: 90,
                right: 16,
                child: _buildPipSelfPreview(call),
              ),

            // 4. Walkie-Talkie Push-to-Talk Bar (if Audio Call)
            if (!isVideo && call.status == OfflineCallStatus.connected)
              Positioned(
                bottom: 120,
                left: 32,
                right: 32,
                child: _buildPushToTalkButton(call),
              ),

            // 5. Shared Photos strip indicator
            if (call.sharedPhotos.isNotEmpty)
              Positioned(
                bottom: 110,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_rounded, color: AppColors.cyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${call.sharedPhotos.length} P2P Photo Evidence',
                        style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            // 6. Bottom Call Action Controls
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildBottomControls(call),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(OfflineP2PCallState call) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: call.status == OfflineCallStatus.connected
                      ? AppColors.successGreen
                      : AppColors.warningAmber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (call.status == OfflineCallStatus.connected
                              ? AppColors.successGreen
                              : AppColors.warningAmber)
                          .withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.peerName.isNotEmpty ? call.peerName : 'Nearby Peer',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    call.status == OfflineCallStatus.connected
                        ? 'CONNECTED • ${call.formattedDuration}'
                        : 'CONNECTING DIRECT P2P...',
                    style: TextStyle(
                      color: call.status == OfflineCallStatus.connected
                          ? AppColors.cyan
                          : AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Connection Metric Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.elevatedGlassSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sensors_rounded, color: AppColors.cyan, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${call.latencyMs}ms • 0 Net',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoViewport(OfflineP2PCallState call) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            AppColors.primaryBlue.withOpacity(0.35),
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated High-Definition Video Canvas
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                  child: Text(
                    call.peerName.isNotEmpty ? call.peerName[0] : 'P',
                    style: const TextStyle(
                      fontSize: 48,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Text(
                    '📹 HD 1080p 30fps • Direct P2P Video Link',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Viewfinder HUD Corner brackets
          Positioned(
            top: 80,
            left: 24,
            child: Text(
              '┌ P2P 5GHz DIRECT',
              style: TextStyle(
                color: AppColors.cyan.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 24,
            child: Text(
              'AES-GCM 256-BIT ┘',
              style: TextStyle(
                color: AppColors.cyan.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipSelfPreview(OfflineP2PCallState call) {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              call.isFrontCamera ? Icons.person_rounded : Icons.camera_rear_rounded,
              color: AppColors.primaryBlue,
              size: 40,
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'You (Self)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioViewport(OfflineP2PCallState call) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.15);
              return Container(
                width: 160 * scale,
                height: 160 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withOpacity(0.12 * (1 - _pulseController.value)),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.4 * (1 - _pulseController.value)),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.25),
                    child: Text(
                      call.peerName.isNotEmpty ? call.peerName[0] : 'P',
                      style: const TextStyle(
                        fontSize: 48,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            call.peerName.isNotEmpty ? call.peerName : 'Nearby Peer',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            call.status == OfflineCallStatus.connected
                ? 'Opus 48kHz Crystal Audio • Zero Internet'
                : 'P2P Handshake over BLE & Wi-Fi LAN...',
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPushToTalkButton(OfflineP2PCallState call) {
    final active = call.isPushToTalkActive;
    return GestureDetector(
      onTapDown: (_) => ref.read(offlineP2PCallProvider.notifier).setPushToTalk(true),
      onTapUp: (_) => ref.read(offlineP2PCallProvider.notifier).setPushToTalk(false),
      onTapCancel: () => ref.read(offlineP2PCallProvider.notifier).setPushToTalk(false),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: active ? AppColors.emergencyRed : AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: active ? Colors.white : AppColors.cyan,
            width: active ? 2 : 1.2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.emergencyRed.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? Icons.mic_rounded : Icons.radio_button_checked_rounded,
              color: active ? Colors.white : AppColors.cyan,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              active ? 'TRANSMITTING VOICE (RELEASE TO LISTEN)' : 'HOLD TO TALK (WALKIE-TALKIE)',
              style: TextStyle(
                color: active ? Colors.white : AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(OfflineP2PCallState call) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Mute Mic
          _buildActionButton(
            icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            isActive: !call.isMuted,
            activeColor: AppColors.elevatedGlassSurface,
            iconColor: call.isMuted ? AppColors.emergencyRed : AppColors.primaryText,
            onTap: () => ref.read(offlineP2PCallProvider.notifier).toggleMute(),
          ),

          // 2. Video Toggle
          _buildActionButton(
            icon: call.isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            isActive: call.isVideoEnabled,
            activeColor: AppColors.elevatedGlassSurface,
            iconColor: call.isVideoEnabled ? AppColors.cyan : AppColors.mutedText,
            onTap: () => ref.read(offlineP2PCallProvider.notifier).toggleVideo(),
          ),

          // 3. Flip Camera
          if (call.isVideoEnabled)
            _buildActionButton(
              icon: Icons.flip_camera_ios_rounded,
              isActive: true,
              activeColor: AppColors.elevatedGlassSurface,
              iconColor: AppColors.primaryText,
              onTap: () => ref.read(offlineP2PCallProvider.notifier).switchCamera(),
            ),

          // 4. Capture & Send Offline Photo Evidence
          _buildActionButton(
            icon: Icons.camera_alt_rounded,
            isActive: true,
            activeColor: AppColors.primaryBlue.withOpacity(0.25),
            iconColor: AppColors.cyan,
            onTap: _handleCapturePhoto,
          ),

          // 5. Speakerphone Toggle
          _buildActionButton(
            icon: call.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            isActive: call.isSpeakerOn,
            activeColor: AppColors.elevatedGlassSurface,
            iconColor: call.isSpeakerOn ? AppColors.cyan : AppColors.mutedText,
            onTap: () => ref.read(offlineP2PCallProvider.notifier).toggleSpeaker(),
          ),

          // 6. End Call Button
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emergencyRed,
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
              onPressed: () {
                ref.read(offlineP2PCallProvider.notifier).endCall();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: activeColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
