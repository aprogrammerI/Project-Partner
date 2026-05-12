import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import '../widgets/profile_form.dart';

/// Shown after register, before reaching the main app. The auth-state
/// listener at the app root automatically routes here whenever the
/// current user has an empty [name]; it routes away again as soon as
/// the form is saved.
class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (user) {
            if (user == null) return const SizedBox.shrink();
            return ProfileForm(
              initial: user,
              submitLabel: 'Save & continue',
              // No-op: app root listener detects the non-empty name and
              // switches to HomeShell on the next build.
            );
          },
        ),
      ),
    );
  }
}
