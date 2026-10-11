import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/nearby/presentation/nearby_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/safe_walk/presentation/safe_walk_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/nearby')) return 1;
    if (location.startsWith('/sos')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/nearby');
        break;
      case 2:
        context.go('/sos');
        break;
      case 3:
        context.go('/community');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.0)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 68,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.location_searching_rounded),
              selectedIcon: Icon(Icons.my_location_rounded),
              label: 'Nearby',
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergencyRed,
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergencyRed,
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
              ),
              label: 'SOS',
            ),
            const NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'Community',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
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
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/nearby',
          builder: (context, state) => const NearbyScreen(),
        ),
        GoRoute(
          path: '/sos',
          builder: (context, state) => const SosScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
