import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'auth_widgets.dart';

/// Shown on app start when there is a saved session with biometrics on.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  var _failed = false;

  @override
  void initState() {
    super.initState();
    // Open the system prompt right away; the button retries.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _unlock();
    });
  }

  Future<void> _unlock() async {
    final ok = await ref.read(authControllerProvider.notifier).unlock();
    if (!ok && mounted) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthNeedsUnlock ? auth.user.firstName : '';

    return AuthScaffold(
      key: const ValueKey('unlock.root'),
      icon: Icons.lock_outline,
      title: 'Hola, $name',
      subtitle: _failed
          ? 'No se pudo verificar tu huella. Intenta de nuevo o usa tu '
                'contraseña.'
          : 'Usa tu huella para entrar',
      children: [
        FilledButton.icon(
          key: const ValueKey('unlock.biometric'),
          onPressed: _unlock,
          icon: const Icon(Icons.fingerprint),
          label: const Text('Desbloquear con huella'),
        ),
        const SizedBox(height: 12),
        TextButton(
          key: const ValueKey('unlock.usePassword'),
          onPressed: () =>
              ref.read(authControllerProvider.notifier).usePassword(),
          child: const Text('Usar contraseña'),
        ),
      ],
    );
  }
}
