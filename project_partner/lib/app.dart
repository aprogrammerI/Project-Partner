import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/home_shell.dart';
import 'features/profile/screens/profile_setup_screen.dart';
import 'services/providers.dart';

class ProjectPartnerApp extends StatelessWidget {
  const ProjectPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Partner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Top-level auth router. Listens to the current-user stream and swaps the
/// root widget based on three states:
///
/// 1. user == null              -> [SplashScreen] (with internal nav to
///                                  Login / Register)
/// 2. user != null, name empty  -> [ProfileSetupScreen] (forced)
/// 3. user != null, name filled -> [HomeShell] (main app)
///
/// Because this lives at the [MaterialApp.home] slot, swapping it tears
/// down any pushed pages above it — so a successful login or register
/// inside a pushed screen automatically returns the user to the right
/// place.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    return userAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (user) {
        if (user == null) return const SplashScreen();
        if (user.name.trim().isEmpty) return const ProfileSetupScreen();
        return const HomeShell();
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong:\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
