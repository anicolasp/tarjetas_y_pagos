import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;

  @override
  void initState() {
    super.initState();
    // Prefill the last user that can log in with biometrics.
    final auth = ref.read(authControllerProvider);
    if (auth is AuthLoggedOut && auth.biometricUser != null) {
      _email.text = auth.biometricUser!.email;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text, _password.text);
    } on InvalidCredentialsException {
      if (mounted) {
        showErrorSnackBar(context, context.l10n.wrongCredentials);
      }
    } on LockedOutException catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          context.l10n.tooManyAttemptsRetryIn(formatWait(e.remaining)),
        );
      }
    } on Exception {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometric() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .loginWithBiometrics();
    if (!ok && mounted) {
      showErrorSnackBar(context, context.l10n.fingerprintVerifyFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final biometricUser = auth is AuthLoggedOut ? auth.biometricUser : null;
    final l = context.l10n;

    return AuthScaffold(
      key: const ValueKey('login.root'),
      title: l.loginTitle,
      subtitle: l.loginSubtitle,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('login.email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => l.fieldError(validateEmail(v)),
                  decoration: InputDecoration(
                    labelText: l.emailLabel,
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  key: const ValueKey('login.password'),
                  toggleKey: const ValueKey('login.togglePassword'),
                  controller: _password,
                  label: l.passwordLabel,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  // Login only checks it is not empty; the rules apply when
                  // registering.
                  validator: (v) => l.fieldError(
                    (v ?? '').isEmpty ? FieldError.passwordRequired : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: const ValueKey('login.forgot'),
            onPressed: _loading
                ? null
                : () => context.push(Routes.forgotPassword),
            child: Text(l.forgotPasswordLink),
          ),
        ),
        const SizedBox(height: 8),
        LoadingButton(
          key: const ValueKey('login.submit'),
          label: l.loginTitle,
          loading: _loading,
          onPressed: _submit,
        ),
        if (biometricUser != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('login.biometric'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _loading ? null : _biometric,
            icon: const Icon(Icons.fingerprint),
            label: Text(l.loginWithFingerprintAs(biometricUser.firstName)),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.noAccount),
            TextButton(
              key: const ValueKey('login.register'),
              onPressed: _loading ? null : () => context.push(Routes.register),
              child: Text(l.createAccount),
            ),
          ],
        ),
      ],
    );
  }
}
