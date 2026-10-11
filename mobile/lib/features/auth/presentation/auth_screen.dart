import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _otpController = TextEditingController(text: '123456');
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _handlePhoneAuth() async {
    setState(() => _isLoading = true);
    if (!_otpSent) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
    } else {
      await ref.read(authProvider.notifier).signInWithPhone(
            _phoneController.text.trim(),
            _otpController.text.trim(),
          );
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/home');
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 36),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign In to GuardVarX',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your verified phone number to connect with your emergency network.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Phone / OTP input card
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: '+91 98765 43210',
                        hintStyle: const TextStyle(color: AppColors.mutedText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.glassBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.glassBorder),
                        ),
                      ),
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Verification OTP',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.primaryText, letterSpacing: 4),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          hintText: '123456',
                          hintStyle: const TextStyle(color: AppColors.mutedText),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.glassBorder),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePhoneAuth,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _otpSent ? 'Verify & Continue' : 'Send Verification OTP',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: AppColors.glassBorder)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.glassBorder)),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign In button
              GlassContainer(
                onTap: _isLoading ? null : _handleGoogleAuth,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata_rounded, color: AppColors.primaryText, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
