import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';

/// A small account form page: [children] above a save button.
class _AccountForm extends StatelessWidget {
  const _AccountForm({
    required this.rootKey,
    required this.title,
    required this.formKey,
    required this.children,
    required this.saveKey,
    required this.saving,
    required this.onSave,
  });

  final Key rootKey;
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Key saveKey;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: rootKey,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: AutofillGroup(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...children,
                    const SizedBox(height: 20),
                    LoadingButton(
                      key: saveKey,
                      label: context.l10n.save,
                      loading: saving,
                      onPressed: onSave,
                    ),
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

/// Shared by the email and password forms: the current password, marked
/// wrong when the repository says so (it stays wrong for that value).
mixin _CurrentPassword<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final current = TextEditingController();
  String? _wrongValue;
  var saving = false;

  String? validateCurrent(String? v) {
    if ((v ?? '').isEmpty) return context.l10n.currentPasswordRequired;
    if (v == _wrongValue) return context.l10n.currentPasswordWrong;
    return null;
  }

  /// Runs [change]; handles the wrong-password, lockout and rule errors.
  Future<void> submit(
    GlobalKey<FormState> form,
    Future<void> Function() change,
    String done,
  ) async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await change();
      if (!mounted) return;
      showErrorSnackBar(context, done);
      context.pop();
    } on WrongPasswordException {
      _wrongValue = current.text;
      if (mounted) form.currentState!.validate();
    } on LockedOutException catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          context.l10n.tooManyAttemptsWait(formatWait(e.remaining)),
        );
      }
    } on EmailTakenException {
      if (mounted) {
        showErrorSnackBar(context, context.l10n.emailHasAccount);
      }
    } on FieldErrorException catch (e) {
      if (mounted) {
        showErrorSnackBar(context, context.l10n.fieldError(e.error)!);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    current.dispose();
    super.dispose();
  }
}

class EditNameScreen extends ConsumerStatefulWidget {
  const EditNameScreen({super.key});

  @override
  ConsumerState<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends ConsumerState<EditNameScreen> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(
    text: ref.read(currentUserProvider)?.firstName,
  );
  late final _last = TextEditingController(
    text: ref.read(currentUserProvider)?.lastName,
  );
  var _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateName(_first.text, _last.text);
      if (mounted) context.pop();
    } on FieldErrorException catch (e) {
      if (mounted) {
        showErrorSnackBar(context, context.l10n.fieldError(e.error)!);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _AccountForm(
      rootKey: const ValueKey('editName.root'),
      title: l.nameAndSurname,
      formKey: _form,
      saveKey: const ValueKey('editName.save'),
      saving: _saving,
      onSave: _save,
      children: [
        TextFormField(
          key: const ValueKey('editName.first'),
          controller: _first,
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
          key: const ValueKey('editName.last'),
          controller: _last,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.familyName],
          validator: (v) =>
              l.fieldError(validateName(v, field: NameField.last)),
          decoration: InputDecoration(
            labelText: l.lastNameLabel,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
      ],
    );
  }
}

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen>
    with _CurrentPassword {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l = context.l10n;
    return _AccountForm(
      rootKey: const ValueKey('changeEmail.root'),
      title: l.changeEmail,
      formKey: _form,
      saveKey: const ValueKey('changeEmail.save'),
      saving: saving,
      onSave: () => submit(
        _form,
        () => ref
            .read(authControllerProvider.notifier)
            .changeEmail(currentPassword: current.text, newEmail: _email.text),
        l.emailUpdated,
      ),
      children: [
        Text(l.currentEmail(user?.email ?? '')),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('changeEmail.email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: (v) => l.fieldError(validateEmail(v)),
          decoration: InputDecoration(
            labelText: l.newEmailLabel,
            prefixIcon: const Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 14),
        PasswordField(
          key: const ValueKey('changeEmail.current'),
          toggleKey: const ValueKey('changeEmail.toggleCurrent'),
          controller: current,
          label: l.currentPasswordLabel,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: validateCurrent,
        ),
      ],
    );
  }
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen>
    with _CurrentPassword {
  final _form = GlobalKey<FormState>();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final l = context.l10n;
    return _AccountForm(
      rootKey: const ValueKey('changePassword.root'),
      title: l.changePassword,
      formKey: _form,
      saveKey: const ValueKey('changePassword.save'),
      saving: saving,
      onSave: () => submit(
        _form,
        () => ref
            .read(authControllerProvider.notifier)
            .changePassword(
              currentPassword: current.text,
              newPassword: _new.text,
            ),
        l.passwordUpdated,
      ),
      children: [
        PasswordField(
          key: const ValueKey('changePassword.current'),
          toggleKey: const ValueKey('changePassword.toggleCurrent'),
          controller: current,
          label: l.currentPasswordLabel,
          autofillHints: const [AutofillHints.password],
          validator: validateCurrent,
        ),
        const SizedBox(height: 14),
        PasswordField(
          key: const ValueKey('changePassword.new'),
          toggleKey: const ValueKey('changePassword.toggleNew'),
          controller: _new,
          label: l.newPasswordLabel,
          autofillHints: const [AutofillHints.newPassword],
          validator: (v) => l.fieldError(
            validatePassword(v) ??
                (v == current.text ? FieldError.samePassword : null),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Text(l.passwordRulesHint(passwordMinLength), style: muted),
        ),
        const SizedBox(height: 14),
        PasswordField(
          key: const ValueKey('changePassword.confirm'),
          toggleKey: const ValueKey('changePassword.toggleConfirm'),
          controller: _confirm,
          label: l.confirmNewPasswordLabel,
          textInputAction: TextInputAction.done,
          validator: (v) =>
              l.fieldError(validatePasswordConfirmation(v, _new.text)),
        ),
      ],
    );
  }
}
