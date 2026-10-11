import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/sos/domain/emergency_model.dart';
import 'package:mobile/features/sos/presentation/widgets/deliberate_hold_button.dart';
import 'package:mobile/features/sos/presentation/widgets/delivery_tracker_widget.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('GuardVarX app starts and displays brand mark on splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GuardVarXApp(),
      ),
    );

    expect(find.text('GUARDVARX'), findsOneWidget);
    expect(find.text('Safety. Connected.'), findsOneWidget);

    // Let the splash screen auto-navigation delay finish
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });

  testWidgets('DeliberateHoldButton quick tap does NOT trigger SOS', (WidgetTester tester) async {
    bool triggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliberateHoldButton(
            holdDuration: const Duration(seconds: 3),
            onTrigger: () {
              triggered = true;
            },
          ),
        ),
      ),
    );

    // Quick tap
    await tester.tap(find.text('HOLD SOS'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(triggered, isFalse, reason: 'Quick tap should not trigger emergency SOS');
  });

  testWidgets('DeliberateHoldButton 3-second deliberate hold triggers SOS', (WidgetTester tester) async {
    bool triggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliberateHoldButton(
            holdDuration: const Duration(seconds: 1), // 1 second hold for unit test
            onTrigger: () {
              triggered = true;
            },
          ),
        ),
      ),
    );

    final finder = find.byType(DeliberateHoldButton);
    expect(finder, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(finder));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(triggered, isTrue, reason: 'Holding for the required duration should trigger SOS');
  });

  test('Emergency incident model adheres to state machine', () {
    final now = DateTime.now();
    var incident = EmergencyIncident(
      incidentId: 'inc_test_123',
      emergencyType: EmergencyType.personalThreat,
      latitude: 28.5355,
      longitude: 77.3910,
      accuracyMeters: 5.0,
      locationTimestamp: now,
      status: DeliveryStatus.localSaved,
    );

    expect(incident.status, equals(DeliveryStatus.localSaved));

    // Transition to server received
    incident = incident.copyWith(
      status: DeliveryStatus.serverReceived,
      receiptId: 'rcpt_verified_999',
    );

    expect(incident.status, equals(DeliveryStatus.serverReceived));
    expect(incident.receiptId, equals('rcpt_verified_999'));
  });

  testWidgets('DeliveryTrackerWidget renders pipeline stages honestly', (WidgetTester tester) async {
    final incident = EmergencyIncident(
      incidentId: 'inc_tracker_1',
      emergencyType: EmergencyType.medical,
      latitude: 12.9716,
      longitude: 77.5946,
      accuracyMeters: 10.0,
      locationTimestamp: DateTime.now(),
      status: DeliveryStatus.serverReceived,
      receiptId: 'rcpt_abc123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliveryTrackerWidget(incident: incident),
        ),
      ),
    );

    expect(find.text('DELIVERY PIPELINE'), findsOneWidget);
    expect(find.text('1. Local Storage Secured'), findsOneWidget);
    expect(find.text('3. Server Confirmed Reception'), findsOneWidget);
    expect(find.textContaining('Receipt ID: rcpt_abc123'), findsOneWidget);
  });
}
