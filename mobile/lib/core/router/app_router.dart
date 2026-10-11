import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/navigation_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/location_details_screen.dart';
import '../../features/nearby/presentation/nearby_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/community/presentation/report_hazard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/safe_walk/presentation/safe_walk_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class MainNavigationShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  late final PageController _pageController;

  final List<Widget> _pages = const [
    HomeScreen(),
    NearbyScreen(),
    SosScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final initialTab = widget.initialIndex;
    _pageController = PageController(initialPage: initialTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(mainNavigationProvider) != initialTab) {
        ref.read(mainNavigationProvider.notifier).setTab(initialTab);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainNavigationProvider);

    // Listen to tab changes from external triggers (e.g. Header avatar, Quick actions)
    ref.listen<int>(mainNavigationProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.jumpToPage(next);
      }
    });

    final notifier = ref.read(mainNavigationProvider.notifier);
    final bool canPop = selectedIndex == 0 && notifier.history.length <= 1;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final handled = notifier.handleBack();
        if (handled && _pageController.hasClients) {
          _pageController.jumpToPage(ref.read(mainNavigationProvider));
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (idx) {
            ref.read(mainNavigationProvider.notifier).setTab(idx);
          },
          children: _pages,
        ),
      ),
    );
  }
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/safewalk',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SafeWalkScreen(),
    ),
    GoRoute(
      path: '/contacts',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: '/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmergencyHistoryScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/location-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LocationDetailsScreen(),
    ),
    GoRoute(
      path: '/report',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportHazardScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'];
        final tab = tabStr != null ? (int.tryParse(tabStr) ?? 0) : 0;
        return MainNavigationShell(initialIndex: tab);
      },
    ),
    GoRoute(
      path: '/nearby',
      redirect: (context, state) => '/home?tab=1',
    ),
    GoRoute(
      path: '/sos',
      redirect: (context, state) => '/home?tab=2',
    ),
    GoRoute(
      path: '/community',
      redirect: (context, state) => '/home?tab=3',
    ),
    GoRoute(
      path: '/profile',
      redirect: (context, state) => '/home?tab=4',
    ),
  ],
);
