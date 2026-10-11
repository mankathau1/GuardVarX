import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class JourneyHistoryItem {
  final String id;
  final String fromAddress;
  final String toAddress;
  final DateTime completedAt;
  final int durationMinutes;
  final double distanceKm;
  final String feedback; // 'Good', 'Okay', 'Need Improvement'
  final List<String> sharedWith;

  JourneyHistoryItem({
    required this.id,
    required this.fromAddress,
    required this.toAddress,
    required this.completedAt,
    required this.durationMinutes,
    required this.distanceKm,
    this.feedback = 'Good',
    this.sharedWith = const [],
  });
}

class SafeWalkSessionState {
  final String id;
  final String destinationName;
  final String startAddress;
  final String status; // 'ACTIVE', 'WARNING', 'INACTIVE'
  final int totalDurationMinutes;
  final int checkinIntervalMinutes;
  final int remainingCheckinSeconds;
  final int elapsedSeconds;
  final DateTime nextCheckinDue;
  final DateTime? startTime;
  final bool isActive;
  final List<String> trustedContactNames;
  final bool isSharingLiveLocation;
  final bool isSharingETA;
  final bool notifyStart;
  final bool notifyComplete;
  final String reminderMethod; // 'Push Notification', 'Vibration + Notification', 'Sound + Vibration'
  final bool routeDeviationDetected;
  final double estimatedDistanceKm;
  final double startLatitude;
  final double startLongitude;
  final double destLatitude;
  final double destLongitude;
  final List<JourneyHistoryItem> history;

  SafeWalkSessionState({
    required this.id,
    required this.destinationName,
    this.startAddress = 'Current Location',
    required this.status,
    this.totalDurationMinutes = 30,
    this.checkinIntervalMinutes = 10,
    required this.remainingCheckinSeconds,
    this.elapsedSeconds = 0,
    required this.nextCheckinDue,
    this.startTime,
    required this.isActive,
    this.trustedContactNames = const [],
    this.isSharingLiveLocation = true,
    this.isSharingETA = true,
    this.notifyStart = true,
    this.notifyComplete = true,
    this.reminderMethod = 'Push Notification',
    this.routeDeviationDetected = false,
    this.estimatedDistanceKm = 2.4,
    this.startLatitude = 13.0418,
    this.startLongitude = 80.2507,
    this.destLatitude = 13.0827,
    this.destLongitude = 80.2707,
    this.history = const [],
  });

  factory SafeWalkSessionState.inactive({List<JourneyHistoryItem>? existingHistory}) {
    return SafeWalkSessionState(
      id: '',
      destinationName: '',
      startAddress: '',
      status: 'INACTIVE',
      remainingCheckinSeconds: 0,
      elapsedSeconds: 0,
      nextCheckinDue: DateTime.now(),
      isActive: false,
      history: existingHistory ?? [
        JourneyHistoryItem(
          id: 'hist_1',
          fromAddress: 'Anna Salai, Teynampet',
          toAddress: 'Home, Anna Nagar',
          completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          durationMinutes: 24,
          distanceKm: 3.2,
          feedback: 'Good',
          sharedWith: ['Aarav Sharma', 'Priya M.'],
        ),
        JourneyHistoryItem(
          id: 'hist_2',
          fromAddress: 'Guindy Metro Station',
          toAddress: 'Office, Tidel Park',
          completedAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
          durationMinutes: 18,
          distanceKm: 2.1,
          feedback: 'Good',
          sharedWith: ['Aarav Sharma'],
        ),
      ],
    );
  }

  SafeWalkSessionState copyWith({
    String? id,
    String? destinationName,
    String? startAddress,
    String? status,
    int? totalDurationMinutes,
    int? checkinIntervalMinutes,
    int? remainingCheckinSeconds,
    int? elapsedSeconds,
    DateTime? nextCheckinDue,
    DateTime? startTime,
    bool? isActive,
    List<String>? trustedContactNames,
    bool? isSharingLiveLocation,
    bool? isSharingETA,
    bool? notifyStart,
    bool? notifyComplete,
    String? reminderMethod,
    bool? routeDeviationDetected,
    double? estimatedDistanceKm,
    double? startLatitude,
    double? startLongitude,
    double? destLatitude,
    double? destLongitude,
    List<JourneyHistoryItem>? history,
  }) {
    return SafeWalkSessionState(
      id: id ?? this.id,
      destinationName: destinationName ?? this.destinationName,
      startAddress: startAddress ?? this.startAddress,
      status: status ?? this.status,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      checkinIntervalMinutes: checkinIntervalMinutes ?? this.checkinIntervalMinutes,
      remainingCheckinSeconds: remainingCheckinSeconds ?? this.remainingCheckinSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      nextCheckinDue: nextCheckinDue ?? this.nextCheckinDue,
      startTime: startTime ?? this.startTime,
      isActive: isActive ?? this.isActive,
      trustedContactNames: trustedContactNames ?? this.trustedContactNames,
      isSharingLiveLocation: isSharingLiveLocation ?? this.isSharingLiveLocation,
      isSharingETA: isSharingETA ?? this.isSharingETA,
      notifyStart: notifyStart ?? this.notifyStart,
      notifyComplete: notifyComplete ?? this.notifyComplete,
      reminderMethod: reminderMethod ?? this.reminderMethod,
      routeDeviationDetected: routeDeviationDetected ?? this.routeDeviationDetected,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      destLatitude: destLatitude ?? this.destLatitude,
      destLongitude: destLongitude ?? this.destLongitude,
      history: history ?? this.history,
    );
  }
}

class SafeWalkNotifier extends StateNotifier<SafeWalkSessionState> {
  final ApiClient apiClient;
  Timer? _ticker;

  SafeWalkNotifier(this.apiClient) : super(SafeWalkSessionState.inactive());

  Future<void> startSafeWalk({
    required String destination,
    String startAddress = 'Current Location',
    int durationMinutes = 30,
    int checkinIntervalMinutes = 10,
    List<String> trustedContactNames = const ['Aarav Sharma'],
    bool isSharingLiveLocation = true,
    bool isSharingETA = true,
    bool notifyStart = true,
    bool notifyComplete = true,
    String reminderMethod = 'Push Notification',
    double startLat = 13.0418,
    double startLng = 80.2507,
    double destLat = 13.0827,
    double destLng = 80.2707,
    double distanceKm = 2.8,
  }) async {
    final now = DateTime.now();
    final nextDue = now.add(Duration(minutes: checkinIntervalMinutes));

    state = SafeWalkSessionState(
      id: 'sw_local_${now.millisecondsSinceEpoch}',
      destinationName: destination,
      startAddress: startAddress,
      status: 'ACTIVE',
      totalDurationMinutes: durationMinutes,
      checkinIntervalMinutes: checkinIntervalMinutes,
      remainingCheckinSeconds: checkinIntervalMinutes * 60,
      elapsedSeconds: 0,
      nextCheckinDue: nextDue,
      startTime: now,
      isActive: true,
      trustedContactNames: trustedContactNames,
      isSharingLiveLocation: isSharingLiveLocation,
      isSharingETA: isSharingETA,
      notifyStart: notifyStart,
      notifyComplete: notifyComplete,
      reminderMethod: reminderMethod,
      routeDeviationDetected: false,
      estimatedDistanceKm: distanceKm,
      startLatitude: startLat,
      startLongitude: startLng,
      destLatitude: destLat,
      destLongitude: destLng,
      history: state.history,
    );

    _startCountdown();

    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.safeWalks,
        data: {
          'destination_name': destination,
          'expected_duration_minutes': durationMinutes,
          'checkin_interval_minutes': checkinIntervalMinutes,
          'trusted_contact_names': trustedContactNames,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final serverId = data['id'] as String? ?? state.id;
      state = state.copyWith(id: serverId);
    } catch (_) {}
  }

  void _startCountdown() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isActive) {
        timer.cancel();
        return;
      }

      final newRemaining = state.remainingCheckinSeconds - 1;
      final newElapsed = state.elapsedSeconds + 1;

      if (newRemaining > 0) {
        state = state.copyWith(
          remainingCheckinSeconds: newRemaining,
          elapsedSeconds: newElapsed,
        );
      } else {
        // Overdue! Transition to WARNING
        state = state.copyWith(
          status: 'WARNING',
          remainingCheckinSeconds: 0,
          elapsedSeconds: newElapsed,
        );
      }
    });
  }

  Future<void> checkin() async {
    final nextDue = DateTime.now().add(Duration(minutes: state.checkinIntervalMinutes));
    state = state.copyWith(
      status: 'ACTIVE',
      remainingCheckinSeconds: state.checkinIntervalMinutes * 60,
      nextCheckinDue: nextDue,
    );
    _startCountdown();

    try {
      await apiClient.dio.post(ApiEndpoints.safeWalkCheckin(state.id));
    } catch (_) {}
  }

  void extendTime(int additionalMinutes) {
    state = state.copyWith(
      status: 'ACTIVE',
      remainingCheckinSeconds: state.remainingCheckinSeconds + (additionalMinutes * 60),
      totalDurationMinutes: state.totalDurationMinutes + additionalMinutes,
      nextCheckinDue: DateTime.now().add(Duration(seconds: state.remainingCheckinSeconds + (additionalMinutes * 60))),
    );
    _startCountdown();
  }

  void toggleLiveSharing(bool enabled) {
    state = state.copyWith(isSharingLiveLocation: enabled);
  }

  void toggleRouteDeviation(bool deviated) {
    state = state.copyWith(routeDeviationDetected: deviated);
  }

  Future<void> complete({String feedback = 'Good'}) async {
    _ticker?.cancel();
    final completedItem = JourneyHistoryItem(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
      fromAddress: state.startAddress.isNotEmpty ? state.startAddress : 'Current Location',
      toAddress: state.destinationName.isNotEmpty ? state.destinationName : 'Destination',
      completedAt: DateTime.now(),
      durationMinutes: (state.elapsedSeconds / 60).ceil().clamp(1, 999),
      distanceKm: state.estimatedDistanceKm,
      feedback: feedback,
      sharedWith: state.trustedContactNames,
    );

    final updatedHistory = [completedItem, ...state.history];
    final currentId = state.id;

    state = SafeWalkSessionState.inactive(existingHistory: updatedHistory);

    try {
      if (currentId.isNotEmpty) {
        await apiClient.dio.post(ApiEndpoints.safeWalkComplete(currentId));
      }
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
