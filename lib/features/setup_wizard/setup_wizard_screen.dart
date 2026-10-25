import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/repositories/auth_repository.dart' show notifyDaysRange;
import '../../services/providers.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';

/// First setup after registering, in 4 steps: currency, first card,
/// biometrics and notifications. "Omitir" (or finishing) goes to Home;
/// the router takes care of it once the pending flag is cleared.
class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  static const _steps = 4;

  var _step = 0;
  var _busy = false;
  var _cardAdded = false;

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  void _next() => setState(() => _step++);

  Future<void> _finish() => ref.read(setupPendingProvider.notifier).done();

  /// Runs [action], showing the generic error if it fails.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addCard() async {
    final saved = await context.push<bool>(Routes.cardNew);
    if (saved == true && mounted) {
      setState(() => _cardAdded = true);
      _next();
    }
  }

  Future<void> _enableBiometrics() => _run(() async {
    final result = await _auth.enableBiometrics();
    if (!mounted) return;
    switch (result) {
      case EnableBiometricsResult.enabled:
        _next();
      case EnableBiometricsResult.unavailable:
        showErrorSnackBar(
          context,
          'Configura una huella en los ajustes del teléfono primero.',
        );
      case EnableBiometricsResult.notConfirmed:
        showErrorSnackBar(context, 'No se confirmó la huella.');
    }
  });

  Future<void> _enableNotifications() => _run(() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!mounted) return;
    if (!granted) {
      showErrorSnackBar(
        context,
        'Sin permiso no podremos avisarte. Puedes darlo luego en los '
        'ajustes del teléfono.',
      );
    }
    await _finish();
  });

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final (icon, title, body) = switch (_step) {
      0 => (
        Icons.payments_outlined,
        '¿En qué moneda gastas más?',
        'Será la moneda que aparece primero en gastos y deudas nuevos.',
      ),
      1 => (
        Icons.credit_card,
        'Agrega tu primera tarjeta',
        'Solo guardamos los últimos 4 dígitos.',
      ),
      2 => (
        Icons.fingerprint,
        'Entra con tu huella',
        'Al abrir la app se pedirá tu huella en vez de la contraseña.',
      ),
      _ => (
        Icons.notifications_outlined,
        'Recordatorios',
        'Te avisamos antes del corte de tus tarjetas, de la fecha límite '
            'de pago y de las deudas por vencer.',
      ),
    };

    final content = switch (_step) {
      0 => _Choices(
        children: [
          for (final c in Currency.values)
            ChoiceChip(
              key: ValueKey('setup.currency.${c.code}'),
              label: Text('${c.symbol} ${c.code}'),
              selected: user.defaultCurrency == c,
              onSelected: (_) =>
                  _run(() => _auth.updatePreferences(defaultCurrency: c)),
            ),
        ],
      ),
      3 => _NoticeDays(
        days: user.notifyDaysBefore,
        onChanged: _busy
            ? null
            : (d) => _run(() => _auth.updatePreferences(notifyDaysBefore: d)),
      ),
      _ => null,
    };

    final (primaryKey, primaryLabel, onPrimary) = switch (_step) {
      0 => ('setup.next', 'Siguiente', _next),
      1 => ('setup.addCard', 'Agregar tarjeta', _addCard),
      2 => ('setup.biometricOn', 'Activar', _enableBiometrics),
      _ => (
        'setup.notificationsOn',
        'Activar recordatorios',
        _enableNotifications,
      ),
    };
    final (laterKey, laterLabel, onLater) = switch (_step) {
      0 => (null, null, null),
      1 => ('setup.cardLater', 'Lo haré después', _next),
      2 => ('setup.biometricLater', 'Ahora no', _next),
      _ => ('setup.notificationsLater', 'Ahora no', () => _run(_finish)),
    };

    return PopScope(
      // Android back goes to the previous step, not out of the app.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        key: const ValueKey('setup.root'),
        appBar: AppBar(
          title: const Text('Configura tu cuenta'),
          automaticallyImplyLeading: false,
          leading: _step == 0
              ? null
              : IconButton(
                  key: const ValueKey('setup.back'),
                  tooltip: 'Atrás',
                  onPressed: () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_back),
                ),
          actions: [
            TextButton(
              key: const ValueKey('setup.skip'),
              onPressed: _busy ? null : () => _run(_finish),
              child: const Text('Omitir'),
            ),
          ],
        ),
        body: SafeArea(
          child: CenteredScrollView(
            child: ResponsiveCenter(
              maxWidth: ContentWidth.form,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Paso ${_step + 1} de $_steps',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          key: const ValueKey('setup.progress'),
                          value: (_step + 1) / _steps,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paso ${_step + 1} de $_steps',
                      key: const ValueKey('setup.stepLabel'),
                      style: text.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          icon,
                          size: 34,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      key: ValueKey('setup.step$_step'),
                      textAlign: TextAlign.center,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (_step == 1 && _cardAdded) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: scheme.primary),
                          const SizedBox(width: 6),
                          const Text('Tarjeta agregada'),
                        ],
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: 24),
                      content,
                    ],
                    const SizedBox(height: 32),
                    LoadingButton(
                      key: ValueKey(primaryKey),
                      label: primaryLabel,
                      loading: _busy,
                      onPressed: onPrimary,
                    ),
                    if (laterKey != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        key: ValueKey(laterKey),
                        onPressed: _busy ? null : onLater,
                        child: Text(laterLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: children,
  );
}

/// "Avisarme N días antes" with − / +.
class _NoticeDays extends StatelessWidget {
  const _NoticeDays({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('Avisarme antes de', style: text.bodyLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('setup.notifyDays.minus'),
              tooltip: 'Menos días',
              onPressed: onChanged == null || days <= notifyDaysRange.min
                  ? null
                  : () => onChanged!(days - 1),
              icon: const Icon(Icons.remove),
            ),
            Text(
              days == 1 ? '1 día' : '$days días',
              key: const ValueKey('setup.notifyDays'),
              style: text.titleMedium,
            ),
            IconButton(
              key: const ValueKey('setup.notifyDays.plus'),
              tooltip: 'Más días',
              onPressed: onChanged == null || days >= notifyDaysRange.max
                  ? null
                  : () => onChanged!(days + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
