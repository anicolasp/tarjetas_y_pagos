import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/greeting.dart';
import '../../core/responsive.dart';
import '../auth/auth_controller.dart';
import '../cards/cards_providers.dart';

/// Temporary profile until the full one lands in #9.
class ProfilePlaceholderScreen extends ConsumerWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      key: const ValueKey('profile.root'),
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: CenteredScrollView(
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    initialsOf(user.firstName, user.lastName),
                    style: text.headlineSmall,
                    textScaler: TextScaler.noScaling,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${user.firstName} ${user.lastName}',
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Muy pronto podrás editar tus datos y preferencias aquí.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  key: const ValueKey('profile.logout'),
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
