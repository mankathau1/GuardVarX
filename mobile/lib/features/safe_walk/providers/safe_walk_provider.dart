import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class SafeWalkSessionState {
  final String id;
  final String destinationName;
  final String status;
  final int remainingCheckinSeconds;
  final DateTime nextCheckinDue;
  final bool isActive;

  SafeWalkSessionState({
    required this.id,
    required this.destinationName,
    required this.status,
    required this.remainingCheckinSeconds,
    required this.nextCheckinDue,
    required this.isActive,
  });

  factory SafeWalkSessionState.inactive() {
    return SafeWalkSessionState(
      id: '',
      destinationName: '',
      status: 'INACTIVE',
      remainingCheckinSeconds: 0,
      nextCheckinDue: DateTime.now(),
      isActive: false,
    );
  }
}

class SafeWalkNotifier extends StateNotifier<SafeWalkSessionState> {
  final ApiClient apiClient;
  Timer? _ticker;

  SafeWalkNotifier(this.apiClient) : super(SafeWalkSessionState.inactive());

  Future<void> startSafeWalk({
    required String destination,
    int durationMinutes = 30,
    int checkinIntervalMinutes = 10,
    List<String> trustedContactIds = const [],
  }) async {
    final nextDue = DateTime.now().add(Duration(minutes: checkinIntervalMinutes));

    state = SafeWalkSessionState(
      id: 'sw_local_${DateTime.now().millisecondsSinceEpoch}',
      destinationName: destination,
      status: 'ACTIVE',
      remainingCheckinSeconds: checkinIntervalMinutes * 60,
      nextCheckinDue: nextDue,
      isActive: true,
    );

    _startCountdown();

    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.safeWalks,
        data: {
          'destination_name': destination,
          'expected_duration_minutes': durationMinutes,
          'checkin_interval_minutes': checkinIntervalMinutes,
          'trusted_contact_ids': trustedContactIds,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final serverId = data['id'] as String? ?? state.id;
      state = SafeWalkSessionState(
        id: serverId,
        destinationName: destination,
        status: 'ACTIVE',
        remainingCheckinSeconds: checkinIntervalMinutes * 60,
        nextCheckinDue: nextDue,
        isActive: true,
      );
    } catch (_) {}
  }

  void _startCountdown() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingCheckinSeconds > 0) {
        state = SafeWalkSessionState(
          id: state.id,
          destinationName: state.destinationName,
          status: state.status,
          remainingCheckinSeconds: state.remainingCheckinSeconds - 1,
          nextCheckinDue: state.nextCheckinDue,
          isActive: state.isActive,
        );
      } else {
        // Overdue! Transition to WARNING
        state = SafeWalkSessionState(
          id: state.id,
          destinationName: state.destinationName,
          status: 'WARNING',
          remainingCheckinSeconds: 0,
          nextCheckinDue: state.nextCheckinDue,
          isActive: state.isActive,
        );
        timer.cancel();
      }
    });
  }

  Future<void> checkin() async {
    final nextDue = DateTime.now().add(const Duration(minutes: 10));
    state = SafeWalkSessionState(
      id: state.id,
      destinationName: state.destinationName,
      status: 'ACTIVE',
      remainingCheckinSeconds: 600,
      nextCheckinDue: nextDue,
      isActive: true,
    );
    _startCountdown();

    try {
      await apiClient.dio.post(ApiEndpoints.safeWalkCheckin(state.id));
    } catch (_) {}
  }

  Future<void> complete() async {
    _ticker?.cancel();
    final id = state.id;
    state = SafeWalkSessionState.inactive();

    try {
      await apiClient.dio.post(ApiEndpoints.safeWalkComplete(id));
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final safeWalkProvider = StateNotifierProvider<SafeWalkNotifier, SafeWalkSessionState>((ref) {
  final client = ref.watch(apiClientProvider);
  return SafeWalkNotifier(client);
});
