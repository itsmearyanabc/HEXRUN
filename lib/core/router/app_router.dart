import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/main_shell.dart';

/// App router configuration using GoRouter
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/map',
    debugLogDiagnostics: true,
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      // Shell routes (with bottom nav)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MapPage(),
            ),
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeaderboardPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // TODO: Add auth check redirect
      return null;
    },
  );
}