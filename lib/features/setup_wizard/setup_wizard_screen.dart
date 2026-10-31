import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../l10n/l10n.dart';
import '../../services/providers.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';
import '../notifications/notice_days_stepper.dart';

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
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
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
        showErrorSnackBar(context, context.l10n.fingerprintUnavailable);
      case EnableBiometricsResult.notConfirmed:
        showErrorSnackBar(context, context.l10n.fingerprintNotConfirmed);
    }
  });

  Future<void> _enableNotifications() => _run(() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!mounted) return;
    if (!granted) {
      showErrorSnackBar(context, context.l10n.notificationsDenied);
    }
    await _finish();
  });

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final (icon, title, body) = switch (_step) {
      0 => (Icons.payments_outlined, l.setupCurrencyTitle, l.setupCurrencyBody),
      1 => (Icons.credit_card, l.setupCardTitle, l.setupCardBody),
      2 => (Icons.fingerprint, l.setupFingerprintTitle, l.setupFingerprintBody),
      _ => (
        Icons.notifications_outlined,
        l.setupRemindersTitle,
        l.setupRemindersBody,
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
      0 => ('setup.next', l.next, _next),
      1 => ('setup.addCard', l.addCard, _addCard),
      2 => ('setup.biometricOn', l.activate, _enableBiometrics),
      _ => ('setup.notificationsOn', l.enableReminders, _enableNotifications),
    };
    final (laterKey, laterLabel, onLater) = switch (_step) {
      0 => (null, null, null),
      1 => ('setup.cardLater', l.illDoItLater, _next),
      2 => ('setup.biometricLater', l.notNow, _next),
      _ => ('setup.notificationsLater', l.notNow, () => _run(_finish)),
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
          title: Text(l.setupTitle),
          automaticallyImplyLeading: false,
          leading: _step == 0
              ? null
              : IconButton(
                  key: const ValueKey('setup.back'),
                  tooltip: l.back,
                  onPressed: () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_back),
                ),
          actions: [
            TextButton(
              key: const ValueKey('setup.skip'),
              onPressed: _busy ? null : () => _run(_finish),
              child: Text(l.skip),
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
                      label: l.stepOf(_step + 1, _steps),
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
                      l.stepOf(_step + 1, _steps),
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
                          Text(l.cardAdded),
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
        Text(context.l10n.notifyBefore, style: text.bodyLarge),
        NoticeDaysStepper(
          days: days,
          onChanged: onChanged,
          keyPrefix: 'setup.notifyDays',
        ),
      ],
    );
  }
}
