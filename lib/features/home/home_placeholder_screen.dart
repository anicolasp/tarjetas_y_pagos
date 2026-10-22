import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../auth/auth_controller.dart';

/// Temporary home until the real one lands in #3.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthLoggedIn ? auth.user.firstName : '';
    final text = Theme.of(context).textTheme;

    return Scaffold(
      key: const ValueKey('home.root'),
      body: SafeArea(
        child: CenteredScrollView(
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hola, $name',
                  key: const ValueKey('home.greeting'),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu inicio llega pronto.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const ValueKey('home.logout'),
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
