import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
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
        showErrorSnackBar(context, 'Correo o contraseña incorrectos');
      }
    } on LockedOutException catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Demasiados intentos. Intenta de nuevo en ${formatWait(e.remaining)}.',
        );
      }
    } on Exception {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometric() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .loginWithBiometrics();
    if (!ok && mounted) {
      showErrorSnackBar(context, 'No se pudo verificar tu huella');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final biometricUser = auth is AuthLoggedOut ? auth.biometricUser : null;

    return AuthScaffold(
      key: const ValueKey('login.root'),
      title: 'Iniciar sesión',
      subtitle: 'Entra para ver tus tarjetas y gastos',
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
                  validator: validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  key: const ValueKey('login.password'),
                  toggleKey: const ValueKey('login.togglePassword'),
                  controller: _password,
                  label: 'Contraseña',
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  // Login only checks it is not empty; the rules apply when
                  // registering.
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Escribe tu contraseña' : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          key: const ValueKey('login.submit'),
          label: 'Iniciar sesión',
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
            label: Text('Entrar con huella como ${biometricUser.firstName}'),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('¿No tienes cuenta?'),
            TextButton(
              key: const ValueKey('login.register'),
              onPressed: _loading ? null : () => context.push(Routes.register),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ],
    );
  }
}
