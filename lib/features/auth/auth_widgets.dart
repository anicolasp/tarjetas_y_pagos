import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../l10n/l10n.dart';

/// Layout shared by the auth screens: centered, width-capped form that
/// scrolls when the screen is short (landscape, big text, keyboard).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.icon = Icons.credit_card,
    this.appBar,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: appBar,
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
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.toggleKey,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final Key toggleKey;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          key: widget.toggleKey,
          tooltip: _obscure
              ? context.l10n.showPassword
              : context.l10n.hidePassword,
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Filled button that shows a spinner and ignores taps while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(label),
    );
  }
}

/// "Ocurrió un error. Intenta de nuevo." in the active language.
String unexpectedError(BuildContext context) => context.l10n.unexpectedError;

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: spokenText(context, message)));
}

/// "30 s", "2 min"…
String formatWait(Duration d) {
  final seconds = d.inSeconds + (d.inMilliseconds % 1000 > 0 ? 1 : 0);
  if (seconds < 60) return '$seconds s';
  return '${(seconds / 60).ceil()} min';
}

/// "¿Eliminar …?" with Cancelar / [confirmLabel] (default "Eliminar").
/// True when confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required Key confirmKey,
  String? confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: confirmKey,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel ?? context.l10n.delete),
          ),
        ],
      ),
    ) ??
    false;

/// A dialog that asks for the password before [onConfirm] (linking or
/// unlinking Google, #37). A wrong password or other known error stays in
/// the dialog as [errorFor]'s text; true once [onConfirm] succeeds. Keys
/// are `<keyPrefix>.dialog`, `.password`, `.error` and `.confirm`.
Future<bool> confirmWithPassword(
  BuildContext context, {
  required String keyPrefix,
  required String title,
  required String body,
  required String confirmLabel,
  required Future<void> Function(String password) onConfirm,
  required String? Function(Object error) errorFor,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _PasswordConfirmDialog(
        keyPrefix: keyPrefix,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        errorFor: errorFor,
      ),
    ) ??
    false;

class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog({
    required this.keyPrefix,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    required this.errorFor,
  });

  final String keyPrefix;
  final String title;
  final String body;
  final String confirmLabel;
  final Future<void> Function(String password) onConfirm;
  final String? Function(Object error) errorFor;

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _password = TextEditingController();
  String? _error;
  var _saving = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving || _password.text.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onConfirm(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = widget.errorFor(e) ?? unexpectedError(context));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.keyPrefix;
    return AlertDialog(
      key: ValueKey('$p.dialog'),
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          const SizedBox(height: 16),
          PasswordField(
            key: ValueKey('$p.password'),
            toggleKey: ValueKey('$p.togglePassword'),
            controller: _password,
            label: l.passwordLabel,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _confirm(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                key: ValueKey('$p.error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: ValueKey('$p.confirm'),
          onPressed: _saving ? null : _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
