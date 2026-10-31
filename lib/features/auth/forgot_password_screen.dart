import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security_question.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// "¿Olvidaste tu contraseña?" (#27): email → security question → new
/// password, then back to the login. Everything stays on the phone.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const _steps = 3;

  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _answer = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _step = 0;
  var _loading = false;
  SecurityQuestion? _question;

  /// Shown under the field that caused it, until it is edited.
  String? _emailError;
  String? _answerError;

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  @override
  void dispose() {
    for (final c in [_email, _answer, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    setState(() => _emailError = _answerError = null);
    if (_loading || !_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final l = context.l10n;
    try {
      switch (_step) {
        case 0:
          _question = await _auth.securityQuestionFor(_email.text);
          setState(() => _step = 1);
        case 1:
          await _auth.checkSecurityAnswer(_email.text, _answer.text);
          setState(() => _step = 2);
        default:
          await _auth.resetPasswordWithAnswer(
            email: _email.text,
            answer: _answer.text,
            newPassword: _password.text,
          );
          if (!mounted) return;
          showErrorSnackBar(context, l.passwordUpdated);
          context.pop();
      }
    } on AccountNotFoundException {
      setState(() => _emailError = l.accountNotFound);
    } on NoSecurityQuestionException {
      setState(() => _emailError = l.noSecurityQuestion);
    } on WrongAnswerException {
      setState(() => _answerError = l.wrongAnswer);
    } on LockedOutException catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          l.tooManyAttemptsWait(formatWait(e.remaining)),
        );
      }
    } on FieldErrorException catch (e) {
      if (mounted) showErrorSnackBar(context, l.fieldError(e.error)!);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final fields = switch (_step) {
      0 => [
        TextFormField(
          key: const ValueKey('forgot.email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          validator: (v) => l.fieldError(validateEmail(v)),
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onFieldSubmitted: (_) => _next(),
          decoration: InputDecoration(
            labelText: l.emailLabel,
            prefixIcon: const Icon(Icons.mail_outline),
            errorText: _emailError,
          ),
        ),
      ],
      1 => [
        Text(
          l.securityQuestionText(_question!),
          key: const ValueKey('forgot.question'),
          style: text.titleMedium,
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('forgot.answer'),
          controller: _answer,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          validator: (v) => l.fieldError(validateSecurityAnswer(v)),
          onChanged: (_) {
            if (_answerError != null) setState(() => _answerError = null);
          },
          onFieldSubmitted: (_) => _next(),
          decoration: InputDecoration(
            labelText: l.securityAnswerLabel,
            prefixIcon: const Icon(Icons.key_outlined),
            errorText: _answerError,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Text(
            l.securityAnswerHint,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
      _ => [
        PasswordField(
          key: const ValueKey('forgot.newPassword'),
          toggleKey: const ValueKey('forgot.toggleNew'),
          controller: _password,
          label: l.newPasswordLabel,
          autofillHints: const [AutofillHints.newPassword],
          validator: (v) => l.fieldError(validatePassword(v)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Text(
            l.passwordRulesHint(passwordMinLength),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 14),
        PasswordField(
          key: const ValueKey('forgot.confirm'),
          toggleKey: const ValueKey('forgot.toggleConfirm'),
          controller: _confirm,
          label: l.confirmNewPasswordLabel,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _next(),
          validator: (v) =>
              l.fieldError(validatePasswordConfirmation(v, _password.text)),
        ),
      ],
    };

    return PopScope(
      // Android back goes to the previous step, then to the login.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: AuthScaffold(
        key: const ValueKey('forgot.root'),
        appBar: AppBar(),
        icon: Icons.lock_reset,
        title: l.forgotTitle,
        subtitle: switch (_step) {
          0 => l.forgotEmailSubtitle,
          1 => l.forgotAnswerSubtitle,
          _ => l.forgotNewPasswordSubtitle,
        },
        children: [
          Text(
            l.stepOf(_step + 1, _steps),
            key: const ValueKey('forgot.stepLabel'),
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: fields,
            ),
          ),
          const SizedBox(height: 24),
          LoadingButton(
            key: ValueKey(_step < 2 ? 'forgot.next' : 'forgot.save'),
            label: _step < 2 ? l.continueLabel : l.save,
            loading: _loading,
            onPressed: _next,
          ),
        ],
      ),
    );
  }
}
