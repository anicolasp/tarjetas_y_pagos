import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
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
                      label: 'Guardar',
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
    if ((v ?? '').isEmpty) return 'Escribe tu contraseña actual';
    if (v == _wrongValue) return 'La contraseña actual no es correcta';
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
          'Demasiados intentos. Espera ${formatWait(e.remaining)}.',
        );
      }
    } on EmailTakenException {
      if (mounted) {
        showErrorSnackBar(context, 'Ese correo ya tiene una cuenta');
      }
    } on ArgumentError catch (e) {
      if (mounted) showErrorSnackBar(context, '${e.message}');
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
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
    } on ArgumentError catch (e) {
      if (mounted) showErrorSnackBar(context, '${e.message}');
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountForm(
      rootKey: const ValueKey('editName.root'),
      title: 'Nombre y apellido',
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
          validator: (v) => validateName(v, field: 'nombre'),
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('editName.last'),
          controller: _last,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.familyName],
          validator: (v) => validateName(v, field: 'apellido'),
          decoration: const InputDecoration(
            labelText: 'Apellido',
            prefixIcon: Icon(Icons.person_outline),
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
    return _AccountForm(
      rootKey: const ValueKey('changeEmail.root'),
      title: 'Cambiar correo',
      formKey: _form,
      saveKey: const ValueKey('changeEmail.save'),
      saving: saving,
      onSave: () => submit(
        _form,
        () => ref
            .read(authControllerProvider.notifier)
            .changeEmail(currentPassword: current.text, newEmail: _email.text),
        'Correo actualizado',
      ),
      children: [
        Text('Correo actual: ${user?.email ?? ''}'),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('changeEmail.email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
          decoration: const InputDecoration(
            labelText: 'Correo nuevo',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 14),
        PasswordField(
          key: const ValueKey('changeEmail.current'),
          toggleKey: const ValueKey('changeEmail.toggleCurrent'),
          controller: current,
          label: 'Contraseña actual',
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
    return _AccountForm(
      rootKey: const ValueKey('changePassword.root'),
      title: 'Cambiar contraseña',
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
        'Contraseña actualizada',
      ),
      children: [
        PasswordField(
          key: const ValueKey('changePassword.current'),
          toggleKey: const ValueKey('changePassword.toggleCurrent'),
          controller: current,
          label: 'Contraseña actual',
          autofillHints: const [AutofillHints.password],
          validator: validateCurrent,
        ),
        const SizedBox(height: 14),
        PasswordField(
          key: const ValueKey('changePassword.new'),
          toggleKey: const ValueKey('changePassword.toggleNew'),
          controller: _new,
          label: 'Contraseña nueva',
          autofillHints: const [AutofillHints.newPassword],
          validator: (v) =>
              validatePassword(v) ??
              (v == current.text ? 'Debe ser distinta de la actual' : null),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Text(
            'Mínimo $passwordMinLength caracteres, con letras y números',
            style: muted,
          ),
        ),
        const SizedBox(height: 14),
        PasswordField(
          key: const ValueKey('changePassword.confirm'),
          toggleKey: const ValueKey('changePassword.toggleConfirm'),
          controller: _confirm,
          label: 'Confirmar contraseña nueva',
          textInputAction: TextInputAction.done,
          validator: (v) => validatePasswordConfirmation(v, _new.text),
        ),
      ],
    );
  }
}
