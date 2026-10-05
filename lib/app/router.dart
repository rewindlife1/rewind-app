import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/assessment/assessment_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/coach/coach_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/pillars/assess_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/track/track_screen.dart';
import '../state/providers.dart';

/// Re-runs router redirects whenever auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

const _authRoutes = {'/login', '/signup', '/reset'};

NoTransitionPage<void> _page(Widget child) => NoTransitionPage(child: child);

final routerProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseProvider);
  final refresh = _AuthRefresh(client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = client.auth.currentSession != null;
      final loc = state.matchedLocation;
      final onAuth = _authRoutes.contains(loc);
      if (!signedIn && !onAuth) return '/login';
      if (signedIn && onAuth) return '/dashboard';
      return null;
    },
    errorBuilder: (context, state) => const _NotFound(),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
      GoRoute(path: '/login', pageBuilder: (c, s) => _page(const AuthScreen(mode: AuthMode.login))),
      GoRoute(path: '/signup', pageBuilder: (c, s) => _page(const AuthScreen(mode: AuthMode.signup))),
      GoRoute(path: '/reset', pageBuilder: (c, s) => _page(const AuthScreen(mode: AuthMode.reset))),
      GoRoute(path: '/assessment', builder: (c, s) => const AssessmentScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (c, s) => _page(const DashboardScreen())),
          GoRoute(path: '/track', pageBuilder: (c, s) => _page(const TrackScreen())),
          GoRoute(
            path: '/assess',
            pageBuilder: (c, s) => _page(const AssessScreen()),
            routes: [
              GoRoute(
                path: ':pillar',
                pageBuilder: (c, s) =>
                    _page(PillarDetailScreen(pillarKey: s.pathParameters['pillar'] ?? '')),
              ),
            ],
          ),
          GoRoute(path: '/coach', pageBuilder: (c, s) => _page(const CoachScreen())),
          GoRoute(path: '/profile', pageBuilder: (c, s) => _page(const ProfileScreen())),
        ],
      ),
    ],
  );
});

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Page not found'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go('/dashboard'), child: const Text('Go to dashboard')),
          ]),
        ),
      );
}
