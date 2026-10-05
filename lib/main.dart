import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'core/env.dart';
import 'core/theme.dart';
import 'ui/widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.isConfigured) {
    await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  }
  runApp(ProviderScope(child: Env.isConfigured ? const RewindApp() : const NotConfiguredApp()));
}

class RewindApp extends ConsumerStatefulWidget {
  const RewindApp({super.key});

  @override
  ConsumerState<RewindApp> createState() => _RewindAppState();
}

class _RewindAppState extends ConsumerState<RewindApp> {
  @override
  void initState() {
    super.initState();
    // After a password-reset link, send the member to Profile to set a new password.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        ref.read(routerProvider).go('/profile');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'REWIND',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Shown when the build is missing SUPABASE_URL / SUPABASE_ANON_KEY.
class NotConfiguredApp extends StatelessWidget {
  const NotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REWIND',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const RewindLogo(),
              const SizedBox(height: 24),
              const ScoreRing(score: 0, size: 160),
              const SizedBox(height: 24),
              Text('REWIND is almost ready.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'This build has no backend connected yet.\nAdd SUPABASE_URL and SUPABASE_ANON_KEY (see README).',
                textAlign: TextAlign.center,
                style: TextStyle(color: RC.muted),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
