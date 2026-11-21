import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/accessibility.dart';
import '../../core/formatters.dart';
import '../../core/greeting.dart';
import '../../core/language.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/notification_service.dart';
import '../../services/providers.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_widgets.dart';
import '../auth/google_sign_in_section.dart' show GoogleLogo;
import '../cards/cards_providers.dart';
import '../notifications/notice_days_stepper.dart';

/// "Mi perfil": data, security, appearance, preferences, categories and
/// logout. Every change applies at once to the whole app.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _busy = false;

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  /// Runs [action], showing the generic error if it fails.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on FieldErrorException catch (e) {
      if (mounted) {
        showErrorSnackBar(context, context.l10n.fieldError(e.error)!);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setA11y(A11ySettings a11y) =>
      _run(() => _auth.updatePreferences(a11y: a11y));

  Future<void> _toggleBiometrics(bool on) => _run(() async {
    if (!on) return _auth.disableBiometrics();
    final result = await _auth.enableBiometrics();
    if (!mounted) return;
    switch (result) {
      case EnableBiometricsResult.enabled:
        showErrorSnackBar(context, context.l10n.fingerprintEnabled);
      case EnableBiometricsResult.unavailable:
        showErrorSnackBar(context, context.l10n.fingerprintUnavailable);
      case EnableBiometricsResult.notConfirmed:
        showErrorSnackBar(context, context.l10n.fingerprintNotConfirmed);
    }
  });

  Future<void> _unlinkGoogle() async {
    final l = context.l10n;
    final unlinked = await confirmWithPassword(
      context,
      keyPrefix: 'googleUnlink',
      title: l.googleUnlinkTitle,
      body: l.googleUnlinkBody,
      confirmLabel: l.googleUnlink,
      onConfirm: (password) =>
          ref.read(authControllerProvider.notifier).unlinkGoogle(password),
      errorFor: (e) => switch (e) {
        WrongPasswordException() => l.wrongPasswordShort,
        LockedOutException(:final remaining) => l.tooManyAttemptsWait(
          formatWait(remaining),
        ),
        _ => null,
      },
    );
    if (unlinked && mounted) {
      showErrorSnackBar(context, context.l10n.googleUnlinked);
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmDestructive(
      context,
      title: context.l10n.logoutConfirmTitle,
      body: context.l10n.logoutConfirmBody,
      confirmLabel: context.l10n.logout,
      confirmKey: const ValueKey('profile.logoutConfirm'),
    );
    if (confirmed) await _auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    const gap = SizedBox(height: 16);

    return Scaffold(
      key: const ValueKey('profile.root'),
      appBar: AppBar(title: Text(l.profileTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(
                      initialsOf(user.firstName, user.lastName),
                      // The theme text color would win over the avatar's.
                      style: text.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${user.firstName} ${user.lastName}',
                  key: const ValueKey('profile.name'),
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
                Text(
                  user.email,
                  key: const ValueKey('profile.email'),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                gap,
                _Section(
                  title: l.sectionData,
                  children: [
                    _NavTile(
                      key: const ValueKey('profile.editName'),
                      icon: Icons.badge_outlined,
                      title: l.nameAndSurname,
                      onTap: () => context.push(Routes.profileName),
                    ),
                    // Both ask for the current password: an account created
                    // with Google sets one first.
                    if (user.hasPassword) ...[
                      _NavTile(
                        key: const ValueKey('profile.changeEmail'),
                        icon: Icons.alternate_email,
                        title: l.changeEmail,
                        onTap: () => context.push(Routes.profileEmail),
                      ),
                      _NavTile(
                        key: const ValueKey('profile.changePassword'),
                        icon: Icons.password,
                        title: l.changePassword,
                        onTap: () => context.push(Routes.profilePassword),
                      ),
                    ] else
                      ListTile(
                        key: const ValueKey('profile.setPassword'),
                        leading: const Icon(Icons.password),
                        title: Text(l.setPassword),
                        subtitle: Text(l.setPasswordHint),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(Routes.profileSetPassword),
                      ),
                  ],
                ),
                gap,
                _Section(
                  title: l.sectionSecurity,
                  children: [
                    SwitchListTile(
                      key: const ValueKey('profile.biometric'),
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(l.fingerprintLogin),
                      subtitle: Text(l.fingerprintLoginSubtitle),
                      value: user.biometricEnabled,
                      onChanged: _busy ? null : _toggleBiometrics,
                    ),
                    if (user.hasGoogle)
                      ListTile(
                        key: const ValueKey('profile.google'),
                        leading: const GoogleLogo(size: 24),
                        title: const Text('Google'),
                        subtitle: Text(l.googleLinkedAs(user.email)),
                        // Only with a password: the account keeps a way in.
                        trailing: user.hasPassword
                            ? TextButton(
                                key: const ValueKey('profile.googleUnlink'),
                                onPressed: _busy ? null : _unlinkGoogle,
                                child: Text(l.googleUnlink),
                              )
                            : null,
                      ),
                    // Recovery replaces a forgotten password: none to recover
                    // until the account has one.
                    if (user.hasPassword)
                      ListTile(
                        key: const ValueKey('profile.securityQuestion'),
                        leading: Icon(
                          user.hasSecurityQuestion
                              ? Icons.help_outline
                              : Icons.warning_amber,
                          color: user.hasSecurityQuestion ? null : scheme.error,
                        ),
                        title: Text(l.securityQuestionLabel),
                        // Without one, the password cannot be recovered: say
                        // so in words, not only with the icon's color.
                        subtitle: Text(
                          user.securityQuestion == null
                              ? l.securityQuestionMissing
                              : l.securityQuestionText(user.securityQuestion!),
                          key: const ValueKey(
                            'profile.securityQuestion.status',
                          ),
                          style: user.hasSecurityQuestion
                              ? null
                              : TextStyle(color: scheme.error),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push(Routes.profileSecurityQuestion),
                      ),
                  ],
                ),
                gap,
                _Section(
                  title: l.sectionAppearance,
                  children: [
                    _FieldLabel(l.themeLabel),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Wrap(
                        key: const ValueKey('profile.theme'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (mode, label, icon) in [
                            (ThemeMode.light, l.themeLight, Icons.light_mode),
                            (ThemeMode.dark, l.themeDark, Icons.dark_mode),
                            (
                              ThemeMode.system,
                              l.themeSystem,
                              Icons.brightness_auto,
                            ),
                          ])
                            ChoiceChip(
                              key: ValueKey('profile.theme.${mode.name}'),
                              avatar: Icon(icon, size: 18),
                              showCheckmark: false,
                              label: Text(label),
                              selected: user.themeMode == mode,
                              onSelected: (_) => _run(
                                () => _auth.updatePreferences(themeMode: mode),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _FieldLabel(l.languageLabel),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Wrap(
                        key: const ValueKey('profile.language'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final language in AppLanguage.values)
                            ChoiceChip(
                              key: ValueKey(
                                'profile.language.${language.code}',
                              ),
                              // Each language in its own words, so anyone can
                              // find theirs.
                              label: Text(language.nativeName),
                              selected: user.language == language,
                              onSelected: (_) => user.language == language
                                  ? null
                                  : _run(
                                      () => _auth.updatePreferences(
                                        language: language,
                                      ),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                gap,
                _Section(
                  title: l.sectionAccessibility,
                  children: [
                    _FieldLabel(l.textSizeLabel),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Wrap(
                        key: const ValueKey('profile.textSize'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (size, label) in [
                            (TextSize.normal, l.textSizeNormal),
                            (TextSize.large, l.textSizeLarge),
                            (TextSize.xlarge, l.textSizeXlarge),
                          ])
                            ChoiceChip(
                              key: ValueKey('profile.textSize.${size.name}'),
                              label: Text(label),
                              selected: user.a11y.textSize == size,
                              // The selected chip stays enabled so it reads
                              // as selected, not greyed out; tapping it
                              // again saves nothing.
                              onSelected: _busy
                                  ? null
                                  : (_) => user.a11y.textSize == size
                                        ? null
                                        : _setA11y(
                                            user.a11y.copyWith(textSize: size),
                                          ),
                            ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      key: const ValueKey('profile.legibleFont'),
                      secondary: const Icon(Icons.font_download_outlined),
                      title: Text(l.legibleFont),
                      subtitle: Text(l.legibleFontSubtitle),
                      value: user.a11y.legibleFont,
                      onChanged: _busy
                          ? null
                          : (on) =>
                                _setA11y(user.a11y.copyWith(legibleFont: on)),
                    ),
                    SwitchListTile(
                      key: const ValueKey('profile.boldText'),
                      secondary: const Icon(Icons.format_bold),
                      title: Text(l.boldText),
                      value: user.a11y.boldText,
                      onChanged: _busy
                          ? null
                          : (on) => _setA11y(user.a11y.copyWith(boldText: on)),
                    ),
                    SwitchListTile(
                      key: const ValueKey('profile.highContrast'),
                      secondary: const Icon(Icons.contrast),
                      title: Text(l.highContrast),
                      value: user.a11y.highContrast,
                      onChanged: _busy
                          ? null
                          : (on) =>
                                _setA11y(user.a11y.copyWith(highContrast: on)),
                    ),
                    const _A11yPreview(),
                    _Brightness(
                      value: user.a11y.brightness,
                      enabled: !_busy,
                      onSave: (value) =>
                          _setA11y(user.a11y.copyWith(brightness: () => value)),
                    ),
                  ],
                ),
                gap,
                _Section(
                  title: l.sectionPreferences,
                  children: [
                    _FieldLabel(l.defaultCurrency),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in Currency.values)
                            ChoiceChip(
                              key: ValueKey('profile.currency.${c.code}'),
                              label: Text('${c.symbol} ${c.code}'),
                              selected: user.defaultCurrency == c,
                              onSelected: (_) => _run(
                                () =>
                                    _auth.updatePreferences(defaultCurrency: c),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _NotifyDays(
                      days: user.notifyDaysBefore,
                      onChanged: _busy
                          ? null
                          : (d) => _run(
                              () =>
                                  _auth.updatePreferences(notifyDaysBefore: d),
                            ),
                    ),
                    const _Reminders(),
                  ],
                ),
                gap,
                _Section(
                  title: l.sectionCategories,
                  children: [
                    _NavTile(
                      key: const ValueKey('profile.categories'),
                      icon: Icons.category_outlined,
                      title: l.myCategories,
                      onTap: () => context.push(Routes.categories),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const ValueKey('profile.logout'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: scheme.error,
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(l.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's own screen brightness (#39): the phone's by default, or a
/// value from [minAppBrightness] to 100 % while the app is open. Dragging
/// previews it; it is saved when the drag ends.
class _Brightness extends ConsumerStatefulWidget {
  const _Brightness({
    required this.value,
    required this.enabled,
    required this.onSave,
  });

  /// Null: the phone's brightness.
  final double? value;
  final bool enabled;
  final Future<void> Function(double? value) onSave;

  @override
  ConsumerState<_Brightness> createState() => _BrightnessState();
}

class _BrightnessState extends ConsumerState<_Brightness> {
  /// The value under the finger, until it is saved.
  double? _dragging;

  Future<void> _save(double? value) async {
    await widget.onSave(value);
    if (!mounted) return;
    setState(() => _dragging = null);
    // A failed save leaves the old setting: show it again.
    if (widget.value != value) {
      final service = ref.read(brightnessServiceProvider);
      final saved = widget.value;
      saved == null ? service.reset() : service.apply(saved);
    }
  }

  Future<void> _useSystem(bool? on) async {
    if (on ?? true) return _save(null);
    // Start from what the phone shows, so the screen does not jump.
    final system = await ref.read(brightnessServiceProvider).system();
    if (!mounted) return;
    await _save((system ?? 1).clamp(minAppBrightness, 1));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final followsPhone = widget.value == null;
    final shown = _dragging ?? widget.value;
    final percent = NumberFormat.percentPattern();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(l.appBrightness),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(
            l.appBrightnessHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.brightness_6_outlined),
              Expanded(
                child: Slider(
                  key: const ValueKey('profile.brightness'),
                  value: shown ?? 1,
                  min: minAppBrightness,
                  divisions: 18,
                  label: percent.format(shown ?? 1),
                  semanticFormatterCallback: percent.format,
                  onChanged: followsPhone || !widget.enabled
                      ? null
                      : (v) {
                          setState(() => _dragging = v);
                          ref.read(brightnessServiceProvider).apply(v);
                        },
                  onChangeEnd: followsPhone || !widget.enabled ? null : _save,
                ),
              ),
              if (shown != null)
                Text(
                  percent.format(shown),
                  key: const ValueKey('profile.brightness.value'),
                ),
            ],
          ),
        ),
        CheckboxListTile(
          key: const ValueKey('profile.brightnessSystem'),
          title: Text(l.useSystemBrightness),
          value: followsPhone,
          onChanged: widget.enabled ? _useSystem : null,
        ),
      ],
    );
  }
}

/// A sample line with the current accessibility settings; the whole app
/// changes at once, so it updates with them.
class _A11yPreview extends StatelessWidget {
  const _A11yPreview();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.a11yPreviewLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          DecoratedBox(
            key: const ValueKey('profile.a11yPreview'),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Text(l.spentThisMonth, style: theme.textTheme.bodyLarge),
                  Text(
                    formatMoney(125000, Currency.dop),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The label above a group of chips inside a section.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Whether Android shows the reminders, and a way to allow them: the
/// permission dialog first, the phone settings once Android stops showing
/// it. Checked again when the user comes back to the app (from the
/// settings, for instance).
class _Reminders extends ConsumerStatefulWidget {
  const _Reminders();

  @override
  ConsumerState<_Reminders> createState() => _RemindersState();
}

class _RemindersState extends ConsumerState<_Reminders> {
  late final AppLifecycleListener _lifecycle;
  bool? _granted;
  var _asking = false;

  /// Bumped by every check and request: an older answer that arrives late
  /// (the dialog itself pauses and resumes the app) is ignored.
  var _version = 0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final version = ++_version;
    final bool granted;
    try {
      granted = await ref.read(notificationServiceProvider).permissionGranted();
    } catch (_) {
      return; // Keep what is shown; the next return to the app retries.
    }
    if (mounted && version == _version) setState(() => _granted = granted);
  }

  Future<void> _enable() async {
    final service = ref.read(notificationServiceProvider);
    final version = ++_version;
    setState(() => _asking = true);
    var granted = false;
    try {
      granted = await service.requestPermission();
    } catch (_) {
      // No dialog could be shown: the settings are the way left.
    } finally {
      if (mounted) setState(() => _asking = false);
    }
    if (!mounted) return;
    if (version == _version) setState(() => _granted = granted);
    if (granted) return;
    // Denied, or Android no longer shows the dialog: only the settings
    // can allow them now.
    final l = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.remindersInSettings),
          action: SnackBarAction(
            key: const ValueKey('profile.reminders.openSettings'),
            label: l.openSettings,
            onPressed: () => _openSettings(service),
          ),
        ),
      );
  }

  Future<void> _openSettings(NotificationService service) async {
    try {
      await service.openSettings();
    } catch (_) {
      // No settings channel on this platform.
      if (mounted) showErrorSnackBar(context, context.l10n.openSettingsHint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return switch (_granted) {
      // About the height of the "on" row, so the page barely moves when
      // the status arrives.
      null => const SizedBox(height: 56),
      true => ListTile(
        key: const ValueKey('profile.reminders.on'),
        leading: Icon(Icons.check_circle, color: scheme.primary),
        title: Text(l.remindersOn),
      ),
      false => Padding(
        key: const ValueKey('profile.reminders.off'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_off_outlined, color: scheme.error),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.remindersOff, style: text.bodyLarge),
                      Text(
                        l.remindersOffHint,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                key: const ValueKey('profile.reminders.enable'),
                onPressed: _asking ? null : _enable,
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(l.enableReminders),
              ),
            ),
          ],
        ),
      ),
    };
  }
}

/// "Días de aviso" with − / + (0–30), for the reminders of #10.
class _NotifyDays extends StatelessWidget {
  const _NotifyDays({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        children: [
          Text(context.l10n.notifyBefore, style: text.bodyLarge),
          NoticeDaysStepper(
            days: days,
            onChanged: onChanged,
            keyPrefix: 'profile.notifyDays',
          ),
        ],
      ),
    );
  }
}
