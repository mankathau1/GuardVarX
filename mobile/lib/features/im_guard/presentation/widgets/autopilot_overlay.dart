import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sos/domain/emergency_model.dart';
import '../../../sos/providers/sos_provider.dart';
import '../../providers/im_guard_provider.dart';
import 'cyber_robotic_hand_widget.dart';
import 'robot_avatar_widget.dart';

class AutopilotOverlay extends ConsumerStatefulWidget {
  const AutopilotOverlay({super.key});

  @override
  ConsumerState<AutopilotOverlay> createState() => _AutopilotOverlayState();
}

class _AutopilotOverlayState extends ConsumerState<AutopilotOverlay>
    with TickerProviderStateMixin {
  // Motion controller for Robotic Hand gliding across screen
  late AnimationController _handMoveController;
  late Animation<Offset> _handMoveAnimation;

  // Tap ripple controller
  late AnimationController _tapRippleController;

  // Green glowing border pulse controller
  late AnimationController _greenGlowController;

  // 3-second SOS Long-Press controller
  late AnimationController _longPressController;

  bool _isTapping = false;
  bool _isLongPressing = false;
  double _longPressProgress = 0.0;
  String _currentActionBadge = 'CALIBRATING AI';
  int _currentStepIndex = 0;
  Timer? _sequenceTimer;
  Timer? _hapticHoldTimer;

  Offset _currentHandPos = const Offset(200, 400);
  bool _sequenceStarted = false;

  @override
  void initState() {
    super.initState();
    _handMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _tapRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _greenGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _longPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _handMoveAnimation = Tween<Offset>(
      begin: const Offset(300, 700),
      end: const Offset(200, 400),
    ).animate(CurvedAnimation(parent: _handMoveController, curve: Curves.easeInOutCubic));

    _handMoveController.addListener(() {
      if (mounted) {
        setState(() {
          _currentHandPos = _handMoveAnimation.value;
        });
      }
    });

    _longPressController.addListener(() {
      if (mounted && _isLongPressing) {
        final val = _longPressController.value;
        final remainingSec = ((1.0 - val) * 3.0).clamp(0.0, 3.0);
        setState(() {
          _longPressProgress = val;
          _currentActionBadge = 'HOLDING SOS: ${remainingSec.toStringAsFixed(1)}s';
        });
      }
    });
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _hapticHoldTimer?.cancel();
    _handMoveController.dispose();
    _tapRippleController.dispose();
    _greenGlowController.dispose();
    _longPressController.dispose();
    super.dispose();
  }

  void _stopAllAutopilotActions() {
    _sequenceTimer?.cancel();
    _hapticHoldTimer?.cancel();
    _sequenceTimer = null;
    _hapticHoldTimer = null;
    _sequenceStarted = false;
    _isLongPressing = false;
    _isTapping = false;
    _longPressProgress = 0.0;
    _currentStepIndex = 0;
    if (_greenGlowController.isAnimating) _greenGlowController.stop();
    if (_handMoveController.isAnimating) _handMoveController.stop();
    if (_longPressController.isAnimating) _longPressController.stop();
  }

  void _runAutopilotSequence(Size screenSize, double topPadding) {
    if (_sequenceStarted) return;
    _sequenceStarted = true;

    final screenW = screenSize.width;
    final screenH = screenSize.height;

    // Start pulsating neon green edge border
    _greenGlowController.repeat(reverse: true);

    // Initial hand position (bottom right)
    _currentStepIndex = 0;
    _currentHandPos = Offset(screenW * 0.85, screenH * 0.85);
    _currentActionBadge = 'AUTONOMOUS OPERATOR ENGAGED';
    _isLongPressing = false;
    _longPressProgress = 0.0;

    // Screen Layout Anchor Offsets
    // HomeScreen SOS button is at center X, Y ~ topPadding + 385px
    final sosX = screenW * 0.5;
    final sosY = topPadding + 385.0;

    // HomeScreen Nearby Help card is on the right side of CentralSosSection
    final nearbyHelpX = screenW * 0.82;
    final nearbyHelpY = sosY;

    // NearbyScreen Helper Card Request button positions (after scrolling 260px)
    final nearbyReqX = screenW * 0.84;
    final helper1Y = topPadding + 312.0; // Dr. Priya M.
    final helper2Y = topPadding + 419.0; // Arunkumar S.
    final helper3Y = topPadding + 526.0; // Kavitha N.

    // STEP 1: Glide hand to Central SOS Button on Main Page
    _sequenceTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _currentStepIndex = 1);
      _glideHandTo(
        target: Offset(sosX, sosY),
        badge: 'TARGET: SOS BUTTON',
        durationMs: 950,
        onArrived: () {
          // STEP 2: 3-Second Long Press on SOS Button
          _execute3SecondSosLongPress(
            onComplete: () {
              // Trigger emergency SOS
              ref.read(sosProvider.notifier).triggerSOS(type: EmergencyType.personalThreat);
              ref.read(imGuardProvider.notifier).updateAutopilotStage(
                    stage: AutopilotStage.activatingSos,
                    actionText: '🚨 STAGE 1: Emergency SOS Fired (3s Deliberate Hold)',
                  );

              // STEP 3: Glide to Nearby Help on Main Page & Tap
              _sequenceTimer = Timer(const Duration(milliseconds: 800), () {
                if (!mounted) return;
                setState(() => _currentStepIndex = 3);
                _glideHandTo(
                  target: Offset(nearbyHelpX, nearbyHelpY),
                  badge: 'TARGET: NEARBY HELP',
                  durationMs: 800,
                  onArrived: () {
                    _performTapAction(
                      badge: 'OPENING NEARBY HELP...',
                      onTapped: () {
                        // Switch to Nearby Screen (Tab 1)
                        ref.read(mainNavigationProvider.notifier).setTab(1);
                        ref.read(imGuardProvider.notifier).updateAutopilotStage(
                              stage: AutopilotStage.dispatchingNearby,
                              actionText: '📍 STAGE 2: Scanning Nearby Helpers...',
                            );

                        // STEP 4: Auto-scroll Nearby screen to reveal helper cards
                        _sequenceTimer = Timer(const Duration(milliseconds: 650), () {
                          if (!mounted) return;
                          setState(() {
                            _currentStepIndex = 4;
                            _currentActionBadge = 'AUTO-SCROLLING HELPERS...';
                          });

                          final nearbyCtrl = ref.read(nearbyScrollControllerProvider);
                          if (nearbyCtrl.hasClients) {
                            nearbyCtrl.animateTo(
                              260.0,
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeInOutCubic,
                            );
                          }

                          // STEP 5: Glide to Helper 1 (Dr. Priya M.) & Tap Request
                          _sequenceTimer = Timer(const Duration(milliseconds: 850), () {
                            if (!mounted) return;
                            setState(() => _currentStepIndex = 5);
                            _glideHandTo(
                              target: Offset(nearbyReqX, helper1Y),
                              badge: 'TARGET: DR. PRIYA M. (260m)',
                              durationMs: 800,
                              onArrived: () {
                                _performTapAction(
                                  badge: 'REQUEST SENT: DR. PRIYA',
                                  onTapped: () {
                                    ref.read(imGuardProvider.notifier).updateAutopilotStage(
                                          stage: AutopilotStage.dispatchingNearby,
                                          actionText: '📍 Dispatching Dr. Priya M. (260m)...',
                                          activeVolunteerName: 'Dr. Priya M.',
                                        );

                                    // STEP 6: Glide to Helper 2 (Arunkumar S.) & Tap Request
                                    _sequenceTimer = Timer(const Duration(milliseconds: 750), () {
                                      if (!mounted) return;
                                      setState(() => _currentStepIndex = 6);
                                      _glideHandTo(
                                        target: Offset(nearbyReqX, helper2Y),
                                        badge: 'TARGET: ARUNKUMAR S. (320m)',
                                        durationMs: 700,
                                        onArrived: () {
                                          _performTapAction(
                                            badge: 'REQUEST SENT: ARUNKUMAR',
                                            onTapped: () {
                                              // STEP 7: Glide to Helper 3 (Kavitha N.) & Tap Request
                                              _sequenceTimer = Timer(const Duration(milliseconds: 750), () {
                                                if (!mounted) return;
                                                setState(() => _currentStepIndex = 7);
                                                _glideHandTo(
                                                  target: Offset(nearbyReqX, helper3Y),
                                                  badge: 'TARGET: KAVITHA N. (480m)',
                                                  durationMs: 700,
                                                  onArrived: () {
                                                    _performTapAction(
                                                      badge: 'REQUEST SENT: KAVITHA',
                                                      onTapped: () {
                                                        // STEP 8: All helpers alerted! Dock hand and complete
                                                        _sequenceTimer = Timer(const Duration(milliseconds: 750), () {
                                                          if (!mounted) return;
                                                          _glideHandTo(
                                                            target: Offset(screenW * 0.84, topPadding + 65.0),
                                                            badge: 'ALL REQUESTS SENT ✅',
                                                            durationMs: 750,
                                                            onArrived: () {
                                                              setState(() {
                                                                _currentStepIndex = 8;
                                                                _currentActionBadge = 'ALL MEASURES ACTIVE';
                                                              });
                                                              ref.read(imGuardProvider.notifier).updateAutopilotStage(
                                                                    stage: AutopilotStage.completed,
                                                                    actionText: '✅ All Nearby Helpers Alerted & SOS Active!',
                                                                  );
                                                            },
                                                          );
                                                        });
                                                      },
                                                    );
                                                  },
                                                );
                                              });
                                            },
                                          );
                                        },
                                      );
                                    });
                                  },
                                );
                              },
                            );
                          });
                        });
                      },
                    );
                  },
                );
              });
            },
          );
        },
      );
    });
  }

  void _execute3SecondSosLongPress({required VoidCallback onComplete}) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _currentStepIndex = 2;
      _isLongPressing = true;
      _longPressProgress = 0.0;
      _currentActionBadge = 'HOLDING SOS: 3.0s';
    });

    _hapticHoldTimer?.cancel();
    _hapticHoldTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      HapticFeedback.selectionClick();
    });

    _longPressController.forward(from: 0.0).whenComplete(() {
      _hapticHoldTimer?.cancel();
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _isLongPressing = false;
          _longPressProgress = 1.0;
          _currentActionBadge = 'SOS ACTIVATED 🚨';
        });
        onComplete();
      }
    });
  }

  void _glideHandTo({
    required Offset target,
    required String badge,
    required int durationMs,
    required VoidCallback onArrived,
  }) {
    if (!mounted) return;
    setState(() {
      _currentActionBadge = badge;
    });

    _handMoveAnimation = Tween<Offset>(
      begin: _currentHandPos,
      end: target,
    ).animate(CurvedAnimation(parent: _handMoveController, curve: Curves.easeInOutCubic));

    _handMoveController.duration = Duration(milliseconds: durationMs);
    _handMoveController.forward(from: 0.0).whenComplete(() {
      if (mounted) onArrived();
    });
  }

  void _performTapAction({
    required String badge,
    required VoidCallback onTapped,
  }) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _isTapping = true;
      _currentActionBadge = badge;
    });

    _tapRippleController.forward(from: 0.0);

    Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      onTapped();
      setState(() {
        _isTapping = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final imGuard = ref.watch(imGuardProvider);

    if (!imGuard.isAutopilotActive) {
      if (_sequenceStarted) {
        _stopAllAutopilotActions();
      }
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final topPadding = media.padding.top;

    // Start choreographed sequence if not yet running
    if (!_sequenceStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && imGuard.isAutopilotActive) {
          _runAutopilotSequence(screenSize, topPadding);
        }
      });
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            // 1. Animated Neon Green Screen Border Glow
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _greenGlowController,
                  builder: (context, child) {
                    final pulse = 0.55 + 0.45 * _greenGlowController.value;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(pulse),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.45 * pulse),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.25 * pulse),
                            blurRadius: 36,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Subtle Darkened Backdrop Vignette for Maximum Contrast
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.3,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF10B981).withOpacity(0.04),
                        Colors.black.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Animated Cyber Robotic Hand Widget Moving Across Screen
            AnimatedBuilder(
              animation: Listenable.merge([_tapRippleController, _longPressController]),
              builder: (context, child) {
                return CyberRoboticHandWidget(
                  position: _currentHandPos,
                  isTapping: _isTapping,
                  isLongPressing: _isLongPressing,
                  longPressProgress: _longPressProgress,
                  tapProgress: _tapRippleController.value,
                  actionBadge: _currentActionBadge,
                );
              },
            ),

            // 4. Top Persistent Autopilot HUD Bar (Live Astra-style Operator Feed)
            Positioned(
              top: topPadding + 8,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _currentStepIndex == 8 ? const Color(0xFF10B981) : AppColors.emergencyRed,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_currentStepIndex == 8 ? const Color(0xFF10B981) : AppColors.emergencyRed).withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    RobotAvatarWidget(
                      size: 38,
                      isEmergencyMode: _currentStepIndex != 8,
                      statusText: '',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                _currentStepIndex == 8
                                    ? 'IM GUARD: ALL HELPERS ALERTED'
                                    : 'IM GUARD: TOTAL CONTROL ACTIVE',
                                style: TextStyle(
                                  color: _currentStepIndex == 8 ? const Color(0xFF10B981) : AppColors.emergencyRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.auto_awesome, color: AppColors.cyan, size: 12),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getActionSubtitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStepIndex == 8 ? const Color(0xFF10B981) : AppColors.emergencyRed,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _stopAllAutopilotActions();
                        ref.read(imGuardProvider.notifier).takeBackControl();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Text(
                              'Manual Control Resumed.',
                              style: TextStyle(color: AppColors.cyan),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        _currentStepIndex == 8 ? 'Done' : 'Take Back',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Mission Accomplished Banner (when all steps complete)
            if (_currentStepIndex == 8)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AUTONOMOUS PROTECTION ENGAGED',
                                  style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'SOS activated & all nearby helpers requested live.',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.glassBorder, height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SuccessStepBadge('SOS Fired (3s)', Icons.check_circle_rounded),
                          _SuccessStepBadge('Dr. Priya (260m)', Icons.check_circle_rounded),
                          _SuccessStepBadge('Arun (320m)', Icons.check_circle_rounded),
                          _SuccessStepBadge('Kavitha (480m)', Icons.check_circle_rounded),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            _stopAllAutopilotActions();
                            ref.read(imGuardProvider.notifier).takeBackControl();
                          },
                          child: const Text('Resume Manual Control', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getActionSubtitle() {
    switch (_currentStepIndex) {
      case 0:
        return 'Calibrating autonomous operator hand...';
      case 1:
        return 'Moving to Emergency SOS Button on Main Page...';
      case 2:
        return 'Holding SOS for 3 seconds deliberate countdown...';
      case 3:
        return 'Tapping Nearby Help Card on Main Page...';
      case 4:
        return 'Auto-scrolling nearby helpers list into view...';
      case 5:
        return 'Dispatching request to Dr. Priya M. (260m)...';
      case 6:
        return 'Dispatching request to Arunkumar S. (320m)...';
      case 7:
        return 'Dispatching request to Kavitha N. (480m)...';
      default:
        return 'All Nearby Helpers Alerted & SOS Active!';
    }
  }
}

class _SuccessStepBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SuccessStepBadge(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.primaryText, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
