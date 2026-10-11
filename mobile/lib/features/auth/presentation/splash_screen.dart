import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Check initial auth state without artificial delays
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final user = ref.read(authProvider);
    if (user.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorderElevated, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.emergencyRedGlow,
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 48,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GUARDVARX',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Safety. Connected.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
