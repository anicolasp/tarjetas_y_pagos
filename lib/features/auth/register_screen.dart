import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _loading = false;

  /// Server-side style error shown under the email field.
  String? _emailError;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _emailError = null);
    if (_loading || !_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            password: _password.text,
          );
    } on EmailTakenException {
      if (mounted) {
        setState(() => _emailError = context.l10n.emailAlreadyRegistered);
      }
    } on Exception {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      key: const ValueKey('register.root'),
      appBar: AppBar(),
      icon: Icons.person_add_alt_1,
      title: l.createAccount,
      subtitle: l.registerSubtitle,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('register.firstName'),
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (v) =>
                      l.fieldError(validateName(v, field: NameField.first)),
                  decoration: InputDecoration(
                    labelText: l.firstNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('register.lastName'),
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  validator: (v) =>
                      l.fieldError(validateName(v, field: NameField.last)),
                  decoration: InputDecoration(
                    labelText: l.lastNameLabel,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('register.email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => l.fieldError(validateEmail(v)),
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  decoration: InputDecoration(
                    labelText: l.emailLabel,
                    prefixIcon: const Icon(Icons.mail_outline),
                    errorText: _emailError,
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  key: const ValueKey('register.password'),
                  toggleKey: const ValueKey('register.togglePassword'),
                  controller: _password,
                  label: l.passwordLabel,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => l.fieldError(validatePassword(v)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    l.passwordRulesHint(passwordMinLength),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  key: const ValueKey('register.confirm'),
                  toggleKey: const ValueKey('register.toggleConfirm'),
                  controller: _confirm,
                  label: l.confirmPasswordLabel,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => l.fieldError(
                    validatePasswordConfirmation(v, _password.text),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          key: const ValueKey('register.submit'),
          label: l.createAccount,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
