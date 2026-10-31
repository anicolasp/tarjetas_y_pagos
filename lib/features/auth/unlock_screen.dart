import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// Shown on app start when there is a saved session with biometrics on.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  /// After this many failed fingerprints only the password is offered.
  static const maxFailures = 3;

  var _failures = 0;

  bool get _failed => _failures > 0;
  bool get _blocked => _failures >= maxFailures;

  @override
  void initState() {
    super.initState();
    // Open the system prompt right away; the button retries.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _unlock();
    });
  }

  Future<void> _unlock() async {
    if (_blocked) return;
    final ok = await ref.read(authControllerProvider.notifier).unlock();
    if (!ok && mounted) setState(() => _failures++);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthNeedsUnlock ? auth.user.firstName : '';
    final l = context.l10n;

    return AuthScaffold(
      key: const ValueKey('unlock.root'),
      icon: Icons.lock_outline,
      title: l.unlockHello(name),
      subtitle: _blocked
          ? l.unlockBlocked
          : _failed
          ? l.unlockFailed
          : l.unlockPrompt,
      children: [
        if (!_blocked) ...[
          FilledButton.icon(
            key: const ValueKey('unlock.biometric'),
            onPressed: _unlock,
            icon: const Icon(Icons.fingerprint),
            label: Text(l.unlockWithFingerprint),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const ValueKey('unlock.usePassword'),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).usePassword(),
            child: Text(l.usePassword),
          ),
        ] else
          FilledButton.icon(
            key: const ValueKey('unlock.usePassword'),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).usePassword(),
            icon: const Icon(Icons.password),
            label: Text(l.loginWithPassword),
          ),
      ],
    );
  }
}
