import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/emergency_permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import 'widgets/emergency_permission_primer_dialog.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.security_rounded,
      'title': 'The Human Emergency Network',
      'subtitle': 'GuardVarX connects you with your trusted contacts, nearby community helpers, and offline mesh safety during critical moments.',
      'tag': 'Safety First',
    },
    {
      'icon': Icons.location_on_rounded,
      'title': 'Consensual Location Sharing',
      'subtitle': 'Your location is NEVER continuously tracked. It is only shared during an active SOS or during a monitored Safe Walk session.',
      'tag': 'Privacy by Default',
    },
    {
      'icon': Icons.wifi_off_rounded,
      'title': 'Offline Store-and-Forward Mesh',
      'subtitle': 'Even with zero cellular reception, emergencies are preserved locally and relayed securely over peer Bluetooth mesh and Wi-Fi Direct.',
      'tag': 'Offline Resilient',
    },
    {
      'icon': Icons.video_call_rounded,
      'title': 'Offline Video & Walkie-Talkie',
      'subtitle': 'Communicate directly with nearby helpers via zero-internet video calls, voice walkie-talkie, and incident photo evidence.',
      'tag': 'Zero Internet P2P',
    },
    {
      'icon': Icons.shield_rounded,
      'title': 'Activate Life-Saving Permissions',
      'subtitle': 'Camera (Video), Microphone (Voice), Nearby Wi-Fi, Bluetooth, Location & Notifications are required for autonomous offline emergency response.',
      'tag': 'Hardware Shield',
      'isPermissionStep': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final permState = ref.watch(emergencyPermissionsProvider);
    final isPermStep = step['isPermissionStep'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top progress bar
              Row(
                children: List.generate(_steps.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primaryBlue
                            : AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),

              // Glass card
              GlassContainer(
                padding: const EdgeInsets.all(28.0),
                borderRadius: 24.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        step['tag'] as String,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      step['icon'] as IconData,
                      size: 48,
                      color: isPermStep ? AppColors.cyan : AppColors.primaryText,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      step['title'] as String,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step['subtitle'] as String,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    if (isPermStep) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: permState.allGranted
                                ? AppColors.successGreen
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              permState.allGranted
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: permState.allGranted
                                  ? AppColors.successGreen
                                  : AppColors.warningAmber,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                permState.allGranted
                                    ? 'All 6 Emergency Permissions Granted!'
                                    : '${permState.grantedCount} of 6 Permissions Active',
                                style: TextStyle(
                                  color: permState.allGranted
                                      ? AppColors.successGreen
                                      : AppColors.primaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Next / Continue / Authorize button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPermStep && !permState.allGranted
                        ? AppColors.cyan
                        : AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (isPermStep) {
                      if (!permState.allGranted) {
                        await EmergencyPermissionPrimerSheet.show(context, onCompleted: () {
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        });
                      } else {
                        context.go('/auth');
                      }
                      return;
                    }

                    if (_currentStep < _steps.length - 1) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      context.go('/auth');
                    }
                  },
                  child: Text(
                    isPermStep
                        ? (permState.allGranted ? 'Finish & Continue' : 'Authorize All Permissions')
                        : (_currentStep == _steps.length - 1 ? 'Get Started' : 'Continue'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
