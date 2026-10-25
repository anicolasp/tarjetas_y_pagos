import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/greeting.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/repositories/auth_repository.dart' show notifyDaysRange;
import '../auth/auth_controller.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';

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
    } on ArgumentError catch (e) {
      if (mounted) showErrorSnackBar(context, '${e.message}');
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleBiometrics(bool on) => _run(() async {
    if (!on) return _auth.disableBiometrics();
    final result = await _auth.enableBiometrics();
    if (!mounted) return;
    switch (result) {
      case EnableBiometricsResult.enabled:
        showErrorSnackBar(context, 'Listo: la app te pedirá tu huella.');
      case EnableBiometricsResult.unavailable:
        showErrorSnackBar(
          context,
          'Configura una huella en los ajustes del teléfono primero.',
        );
      case EnableBiometricsResult.notConfirmed:
        showErrorSnackBar(context, 'No se confirmó la huella.');
    }
  });

  Future<void> _logout() async {
    final confirmed = await confirmDestructive(
      context,
      title: '¿Cerrar sesión?',
      body: 'Tus datos quedan guardados en este teléfono.',
      confirmLabel: 'Cerrar sesión',
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
    const gap = SizedBox(height: 16);

    return Scaffold(
      key: const ValueKey('profile.root'),
      appBar: AppBar(title: const Text('Mi perfil')),
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
                      style: text.headlineSmall,
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
                  title: 'Datos',
                  children: [
                    _NavTile(
                      key: const ValueKey('profile.editName'),
                      icon: Icons.badge_outlined,
                      title: 'Nombre y apellido',
                      onTap: () => context.push(Routes.profileName),
                    ),
                    _NavTile(
                      key: const ValueKey('profile.changeEmail'),
                      icon: Icons.alternate_email,
                      title: 'Cambiar correo',
                      onTap: () => context.push(Routes.profileEmail),
                    ),
                    _NavTile(
                      key: const ValueKey('profile.changePassword'),
                      icon: Icons.password,
                      title: 'Cambiar contraseña',
                      onTap: () => context.push(Routes.profilePassword),
                    ),
                  ],
                ),
                gap,
                _Section(
                  title: 'Seguridad',
                  children: [
                    SwitchListTile(
                      key: const ValueKey('profile.biometric'),
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Entrar con huella'),
                      subtitle: const Text(
                        'Al abrir la app se pide tu huella.',
                      ),
                      value: user.biometricEnabled,
                      onChanged: _busy ? null : _toggleBiometrics,
                    ),
                  ],
                ),
                gap,
                _Section(
                  title: 'Apariencia',
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Wrap(
                        key: const ValueKey('profile.theme'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (mode, label, icon) in const [
                            (ThemeMode.light, 'Claro', Icons.light_mode),
                            (ThemeMode.dark, 'Oscuro', Icons.dark_mode),
                            (
                              ThemeMode.system,
                              'Sistema',
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
                  ],
                ),
                gap,
                _Section(
                  title: 'Preferencias',
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(
                        'Moneda predeterminada',
                        style: text.bodyLarge,
                      ),
                    ),
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
                  ],
                ),
                gap,
                _Section(
                  title: 'Categorías',
                  children: [
                    _NavTile(
                      key: const ValueKey('profile.categories'),
                      icon: Icons.category_outlined,
                      title: 'Mis categorías',
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
          Text('Avisarme antes de', style: text.bodyLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('profile.notifyDays.minus'),
                tooltip: 'Menos días',
                onPressed: onChanged == null || days <= notifyDaysRange.min
                    ? null
                    : () => onChanged!(days - 1),
                icon: const Icon(Icons.remove),
              ),
              Text(
                days == 1 ? '1 día' : '$days días',
                key: const ValueKey('profile.notifyDays'),
                style: text.titleMedium,
              ),
              IconButton(
                key: const ValueKey('profile.notifyDays.plus'),
                tooltip: 'Más días',
                onPressed: onChanged == null || days >= notifyDaysRange.max
                    ? null
                    : () => onChanged!(days + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
