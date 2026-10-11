import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImGuardMessage {
  final String id;
  final String sender; // 'user' or 'im_guard'
  final String text;
  final DateTime timestamp;
  final bool isEmergencyTrigger;
  final List<String>? executedActions;

  ImGuardMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isEmergencyTrigger = false,
    this.executedActions,
  });
}

enum AutopilotStage {
  idle,
  confirming,
  activatingSos,
  dispatchingNearby,
  alertingContacts,
  navigatingSafeZone,
  completed,
}

class ImGuardState {
  final List<ImGuardMessage> messages;
  final bool isLoading;
  final bool isAutopilotActive;
  final AutopilotStage currentStage;
  final String currentActionText;
  final String? activeVolunteerName;

  ImGuardState({
    required this.messages,
    this.isLoading = false,
    this.isAutopilotActive = false,
    this.currentStage = AutopilotStage.idle,
    this.currentActionText = '',
    this.activeVolunteerName,
  });

  ImGuardState copyWith({
    List<ImGuardMessage>? messages,
    bool? isLoading,
    bool? isAutopilotActive,
    AutopilotStage? currentStage,
    String? currentActionText,
    String? activeVolunteerName,
  }) {
    return ImGuardState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isAutopilotActive: isAutopilotActive ?? this.isAutopilotActive,
      currentStage: currentStage ?? this.currentStage,
      currentActionText: currentActionText ?? this.currentActionText,
      activeVolunteerName: activeVolunteerName ?? this.activeVolunteerName,
    );
  }
}

class ImGuardNotifier extends StateNotifier<ImGuardState> {
  final Ref ref;
  Timer? _autopilotTimer;

  static const String _geminiApiKey = 'AIzaSyBF0d4p4BgfodP-TsqCJJBoqXZqcUQOE6k';
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey';

  ImGuardNotifier(this.ref)
      : super(
          ImGuardState(
            messages: [
              ImGuardMessage(
                id: 'init_1',
                sender: 'im_guard',
                text:
                    'Hello! I am IM GUARD, your 24/7 AI Autonomous Safety Guardian. If you are ever in danger, say "Help", "Emergency", or describe what is happening. I can take autonomous control of GuardVarX to protect you instantly.',
                timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
              ),
            ],
          ),
        );

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ImGuardMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    // Check emergency trigger keywords
    final lower = text.toLowerCase();
    final isEmergency = lower.contains('help') ||
        lower.contains('emergency') ||
        lower.contains('danger') ||
        lower.contains('follow') ||
        lower.contains('threat') ||
        lower.contains('accident') ||
        lower.contains('save') ||
        lower.contains('காப்பாத்து') ||
        lower.contains('உதவி') ||
        lower.contains('ஆபத்து');

    if (isEmergency) {
      // Immediate emergency response + prompt for total control authorization
      state = state.copyWith(
        isLoading: false,
        messages: [
          ...state.messages,
          ImGuardMessage(
            id: 'img_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'im_guard',
            text:
                '🚨 THREAT DETECTED! I am standing by to engage Autonomous App Control. Please confirm authorization to let me navigate the app and dispatch emergency protocols.',
            timestamp: DateTime.now(),
            isEmergencyTrigger: true,
          ),
        ],
      );
      return;
    }

    // Call Gemini 1.5 API for conversational safety advice
    try {
      final dio = Dio();
      final response = await dio.post(
        _geminiEndpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'You are "IM GUARD", the official AI Safety Guardian of the GuardVarX safety application. Provide concise, protective, calm, and practical safety advice in 2-3 sentences. If Tamil is used, respond in friendly supportive Tanglish/Tamil. User says: $text'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 200,
          }
        },
      );

      final candidates = response.data['candidates'] as List?;
      String aiText = 'I am with you. Stay alert and keep to well-lit areas.';
      if (candidates != null && candidates.isNotEmpty) {
        aiText = candidates[0]['content']['parts'][0]['text'] as String;
      }

      state = state.copyWith(
        isLoading: false,
        messages: [
          ...state.messages,
          ImGuardMessage(
            id: 'img_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'im_guard',
            text: aiText.trim(),
            timestamp: DateTime.now(),
          ),
        ],
      );
    } catch (_) {
      // Offline fallback
      state = state.copyWith(
        isLoading: false,
        messages: [
          ...state.messages,
          ImGuardMessage(
            id: 'img_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'im_guard',
            text:
                'I am with you. Stay calm, keep in well-lit public areas, and let me know if you need me to take emergency control.',
            timestamp: DateTime.now(),
          ),
        ],
      );
    }
  }

  void startAutonomousOverride() {
    state = state.copyWith(
      isAutopilotActive: true,
      currentStage: AutopilotStage.activatingSos,
      currentActionText: '🚨 IM GUARD: AUTONOMOUS OPERATOR ENGAGED',
    );
  }

  void updateAutopilotStage({
    required AutopilotStage stage,
    required String actionText,
    String? activeVolunteerName,
  }) {
    state = state.copyWith(
      currentStage: stage,
      currentActionText: actionText,
      activeVolunteerName: activeVolunteerName ?? state.activeVolunteerName,
    );
  }

  void takeBackControl() {
    _autopilotTimer?.cancel();
    state = state.copyWith(
      isAutopilotActive: false,
      currentStage: AutopilotStage.idle,
      currentActionText: '',
    );
  }

  @override
  void dispose() {
    _autopilotTimer?.cancel();
    super.dispose();
  }
}

final homeScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final nearbyScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final imGuardProvider = StateNotifierProvider<ImGuardNotifier, ImGuardState>((ref) {
  return ImGuardNotifier(ref);
});
