import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/main_shell.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/map/presentation/pages/map_page.dart';
import 'features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: HexRunApp()));
}

class HexRunApp extends ConsumerWidget {
  const HexRunApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState.isLoading) return null; // Wait for auth state to resolve
      
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const MapPage()),
          GoRoute(path: '/leaderboard', builder: (context, state) => const LeaderboardPage()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.explore_off, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
    ]))),
  );
});