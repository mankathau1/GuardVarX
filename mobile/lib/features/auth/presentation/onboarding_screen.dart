import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
      'subtitle': 'Even with zero cellular reception, emergencies are preserved locally and relayed securely over peer Bluetooth mesh.',
      'tag': 'Offline Resilient',
    },
    {
      'icon': Icons.info_outline_rounded,
      'title': 'Important Safety Disclaimer',
      'subtitle': 'GuardVarX is an additional civilian safety tool. It does NOT automatically replace official emergency services. In severe danger, call India 112 directly.',
      'tag': 'Honest & Transparent',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

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
                      color: AppColors.primaryText,
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
                  ],
                ),
              ),

              const Spacer(),

              // Next / Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep < _steps.length - 1) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      context.go('/auth');
                    }
                  },
                  child: Text(
                    _currentStep == _steps.length - 1 ? 'Get Started' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
