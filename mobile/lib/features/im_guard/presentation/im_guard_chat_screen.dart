import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../providers/im_guard_provider.dart';
import 'widgets/robot_avatar_widget.dart';

class ImGuardChatScreen extends ConsumerStatefulWidget {
  const ImGuardChatScreen({super.key});

  @override
  ConsumerState<ImGuardChatScreen> createState() => _ImGuardChatScreenState();
}

class _ImGuardChatScreenState extends ConsumerState<ImGuardChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPanicChips = [
    '🚨 Help me now!',
    '🚶‍♂️ Someone is following me',
    '🩸 Accident / Medical emergency',
    '🚕 Driver is taking wrong route',
    '🛡️ I need an urgent escort',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? textToSend]) {
    final text = textToSend ?? _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(imGuardProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showAutonomousWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.emergencyRed, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'EMERGENCY AUTONOMOUS OVERRIDE',
                style: TextStyle(
                  color: AppColors.emergencyRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: RobotAvatarWidget(
                size: 70,
                isEmergencyMode: true,
                statusText: 'AUTONOMOUS PILOT',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You have reported an urgent threat. Do you authorize IM GUARD to take TOTAL AUTONOMOUS CONTROL of GuardVarX?',
              style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IM GUARD will automatically execute:', style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('1. Trigger High-Priority Emergency SOS', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  Text('2. Dispatch nearest verified volunteers (Dr. Priya 260m)', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  Text('3. Transmit live GPS coordinates to family', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  Text('4. Locate closest police station & prepare 112 call', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('NO, Manual Only', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              HapticFeedback.heavyImpact();

              // Close chat screen and hand over control to main navigation shell
              if (context.canPop()) {
                context.pop();
              }

              // Return to Main Page (HomeScreen / Tab 0)
              ref.read(mainNavigationProvider.notifier).setTab(0);

              // Start autonomous autopilot sequence
              ref.read(imGuardProvider.notifier).startAutonomousOverride();
            },
            child: const Text(
              'YES, TAKE CONTROL',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imGuard = ref.watch(imGuardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Header with Robot Avatar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 18),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    const RobotAvatarWidget(
                      size: 42,
                      isEmergencyMode: false,
                      statusText: '',
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'IM GUARD',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.verified_rounded, size: 14, color: AppColors.cyan),
                            ],
                          ),
                          Text(
                            'Autonomous 24/7 AI Safety Guardian',
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(mainNavigationProvider.notifier).setTab(2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'SOS',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.glassBorder, height: 1),

              // 2. Chat Messages Stream
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: imGuard.messages.length,
                  itemBuilder: (context, idx) {
                    final msg = imGuard.messages[idx];
                    final isAi = msg.sender == 'im_guard';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Column(
                        crossAxisAlignment:
                            isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment:
                                isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isAi) ...[
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFF00E5FF),
                                  child: Icon(Icons.smart_toy_rounded, size: 14, color: Colors.black),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isAi
                                        ? (msg.isEmergencyTrigger
                                            ? AppColors.emergencyRed.withOpacity(0.18)
                                            : AppColors.surface)
                                        : AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isAi
                                          ? (msg.isEmergencyTrigger
                                              ? AppColors.emergencyRed
                                              : AppColors.glassBorder)
                                          : Colors.transparent,
                                      width: msg.isEmergencyTrigger ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isAi
                                          ? (msg.isEmergencyTrigger
                                              ? AppColors.emergencyRed
                                              : AppColors.primaryText)
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: msg.isEmergencyTrigger
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // If message triggered emergency intent, render the Action Card!
                          if (msg.isEmergencyTrigger) ...[
                            const SizedBox(height: 10),
                            GlassCard(
                              padding: const EdgeInsets.all(14),
                              borderRadius: 16,
                              borderColor: AppColors.emergencyRed,
                              glowColor: AppColors.emergencyRed.withOpacity(0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.shield_rounded, color: AppColors.emergencyRed, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'AUTONOMOUS APP CONTROL READY',
                                        style: TextStyle(
                                          color: AppColors.emergencyRed,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'IM GUARD will automate screen actions, fire SOS, alert verified volunteers, and notify family instantly.',
                                    style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 42,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                                      label: const Text(
                                        'GRANT AUTONOMOUS CONTROL',
                                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.emergencyRed,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: _showAutonomousWarningDialog,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (imGuard.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan)),
                      SizedBox(width: 8),
                      Text('IM GUARD is analyzing safety context...', style: TextStyle(color: AppColors.cyan, fontSize: 11)),
                    ],
                  ),
                ),

              // 3. Quick Panic Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: _quickPanicChips.map((chip) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ActionChip(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.glassBorder),
                        label: Text(chip, style: const TextStyle(color: AppColors.primaryText, fontSize: 11)),
                        onPressed: () => _handleSend(chip),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 4. Message Input Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (v) => _handleSend(),
                          decoration: const InputDecoration(
                            hintText: 'Speak or type to IM GUARD (e.g. Help me)...',
                            hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _handleSend(),
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
