import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/home/presentation/widgets/central_sos_section.dart';
import 'package:mobile/features/home/presentation/widgets/home_header.dart';
import 'package:mobile/features/home/presentation/widgets/location_card.dart';
import 'package:mobile/features/home/presentation/widgets/safety_status_card.dart';
import 'package:mobile/features/home/presentation/widgets/quick_action_card.dart';
import 'package:mobile/features/home/presentation/widgets/safe_walk_session_card.dart';
import 'package:mobile/features/home/presentation/widgets/safety_tip_card.dart';
import 'package:mobile/features/home/presentation/widgets/bottom_navigation.dart';
import 'package:mobile/features/sos/domain/emergency_model.dart';
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

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });

  testWidgets('HomeScreen renders complete layout without overflow on 390x844 viewport', (WidgetTester tester) async {
    // Set standard phone logical resolution (iPhone / Pixel: 390x844)
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all key sections from the master reference layout:
    // 1. Header
    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.text('Safety. Connected.'), findsOneWidget);

    // 2. Safety Status Card
    expect(find.byType(SafetyStatusCard), findsOneWidget);
    expect(find.text('You are safe'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);

    // 3. Current Location Card
    expect(find.byType(LocationCard), findsOneWidget);
    expect(find.text('Current Location'), findsOneWidget);
    expect(find.text('Anna Salai, Teynampet'), findsOneWidget);

    // 4. Central SOS Section
    expect(find.byType(CentralSosSection), findsOneWidget);
    expect(find.text('Safe Walk'), findsWidgets);
    expect(find.text('Nearby Help'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Hold for 3 seconds'), findsOneWidget);

    // 5. Quick-Action Cards (2x2 Grid)
    expect(find.byType(QuickActionCard), findsNWidgets(4));
    expect(find.text('Trusted Contacts'), findsOneWidget);
    expect(find.text('Emergency History'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Report Something'), findsOneWidget);

    // 6. Safe Walk Session Card
    expect(find.byType(SafeWalkSessionCard), findsOneWidget);
    expect(find.text('Start a safe journey to share your live location'), findsOneWidget);

    // 7. Safety Tip Card
    expect(find.byType(SafetyTipCard), findsOneWidget);
    expect(find.text('Safety Tip'), findsOneWidget);
  });

  testWidgets('Central SOS Section deliberate hold activates callback', (WidgetTester tester) async {
    bool sosFired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CentralSosSection(
            holdDuration: const Duration(seconds: 1), // 1s for fast unit test
            onSosTriggered: () {
              sosFired = true;
            },
            onSafeWalkTap: () {},
            onNearbyHelpTap: () {},
          ),
        ),
      ),
    );

    final sosFinder = find.text('SOS');
    expect(sosFinder, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(sosFinder));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(sosFired, isTrue, reason: 'Holding SOS for the specified duration must fire the trigger');
  });

  testWidgets('Horizontal swipe on SOS button does NOT trigger emergency alert', (WidgetTester tester) async {
    bool sosFired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CentralSosSection(
            holdDuration: const Duration(seconds: 1),
            onSosTriggered: () {
              sosFired = true;
            },
            onSafeWalkTap: () {},
            onNearbyHelpTap: () {},
          ),
        ),
      ),
    );

    // Perform a horizontal fling/drag across the SOS button
    await tester.fling(find.text('SOS'), const Offset(200, 0), 1000);
    await tester.pumpAndSettle();

    expect(sosFired, isFalse, reason: 'A horizontal swipe must NEVER trigger SOS');
  });

  testWidgets('CustomFloatingBottomNav renders 5 destinations and switches tabs', (WidgetTester tester) async {
    int currentTab = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomFloatingBottomNav(
                selectedIndex: currentTab,
                onIndexChanged: (idx) {
                  setState(() => currentTab = idx);
                },
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap Nearby tab
    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    expect(currentTab, equals(1));

    // Tap Community tab
    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    expect(currentTab, equals(3));
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

  testWidgets('MainNavigationShell disables swiping across tabs and navigates via tap actions gracefully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationShell(initialIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initially at Home
    expect(find.text('Safety. Connected.'), findsOneWidget);

    // 1. Swiping left across the PageView does NOT change tab (physics is NeverScrollableScrollPhysics)
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
    await tester.pumpAndSettle();
    expect(find.text('Safety. Connected.'), findsOneWidget);

    // 2. Tap Nearby Help card to navigate to Nearby (tab 1)
    await tester.tap(find.text('Nearby Help'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby Help'), findsWidgets);

    // 3. Test on-screen AppBar back button -> Returns to previous page (Home)
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Safety. Connected.'), findsOneWidget);

    // 4. Tap Profile avatar in HomeHeader -> Navigates to Profile (tab 4)
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);

    // 5. Test back from Profile -> Returns to Home (the root)
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Safety. Connected.'), findsOneWidget);
  });
}
