import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/google_auth_service.dart';
import '../../services/providers.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// "— o —" and "Continuar con Google" (#37), on the login and register
/// screens. Hidden when the app has no Google client id. An email that
/// already has an account is linked with its password first.
class GoogleSignInSection extends ConsumerStatefulWidget {
  const GoogleSignInSection({
    super.key,
    required this.keyPrefix,
    this.enabled = true,
  });

  /// `login` or `register`: the button is `<keyPrefix>.google`.
  final String keyPrefix;

  /// False while the screen's own form is busy.
  final bool enabled;

  @override
  ConsumerState<GoogleSignInSection> createState() =>
      _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends ConsumerState<GoogleSignInSection> {
  var _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    GoogleIdentity? toLink;
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
    } on GoogleLinkRequired catch (e) {
      toLink = e.identity;
    } on GoogleSignInFailedException catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          e.failure == GoogleSignInFailure.misconfigured
              ? context.l10n.googleMisconfigured
              : context.l10n.googleFailed,
        );
      }
    } on Exception {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Not spinning behind the dialog: the dialog has its own progress.
    if (toLink != null && mounted) await _link(toLink);
  }

  Future<void> _link(GoogleIdentity identity) => showDialog<void>(
    context: context,
    builder: (_) => _LinkDialog(identity: identity),
  );

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(googleAuthServiceProvider).available) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    final muted = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: muted)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l.orDivider),
            ),
            Expanded(child: Divider(color: muted)),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: ValueKey('${widget.keyPrefix}.google'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _loading || !widget.enabled ? null : _signIn,
          icon: _loading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const GoogleLogo(size: 20),
          label: Text(l.continueWithGoogle),
        ),
      ],
    );
  }
}

/// The Google account's email has an account without Google: its password
/// links them and signs in. A wrong password keeps the dialog open.
class _LinkDialog extends ConsumerStatefulWidget {
  const _LinkDialog({required this.identity});

  final GoogleIdentity identity;

  @override
  ConsumerState<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends ConsumerState<_LinkDialog> {
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
    final l = context.l10n;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .linkGoogleAndLogin(widget.identity, _password.text);
      if (mounted) Navigator.pop(context);
    } on InvalidCredentialsException {
      if (mounted) setState(() => _error = l.wrongPasswordShort);
    } on LockedOutException catch (e) {
      if (mounted) {
        setState(
          () => _error = l.tooManyAttemptsRetryIn(formatWait(e.remaining)),
        );
      }
    } on GoogleAccountTakenException {
      if (mounted) setState(() => _error = l.googleAccountTaken);
    } on Exception {
      if (mounted) setState(() => _error = unexpectedError(context));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      key: const ValueKey('googleLink.dialog'),
      scrollable: true,
      title: Text(l.googleLinkTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.googleLinkBody(widget.identity.email)),
          const SizedBox(height: 16),
          PasswordField(
            key: const ValueKey('googleLink.password'),
            toggleKey: const ValueKey('googleLink.togglePassword'),
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
                key: const ValueKey('googleLink.error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('googleLink.confirm'),
          onPressed: _saving ? null : _confirm,
          child: Text(l.googleLink),
        ),
      ],
    );
  }
}

/// Google's four-color "G", drawn so no image asset is needed.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: (s - stroke) / 2,
    );
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;
    // Clockwise from the right, leaving the opening at the top right.
    canvas
      ..drawArc(rect, deg(-10), deg(55), false, arc(_blue))
      ..drawArc(rect, deg(45), deg(90), false, arc(_green))
      ..drawArc(rect, deg(135), deg(90), false, arc(_yellow))
      ..drawArc(rect, deg(225), deg(85), false, arc(_red))
      // The bar of the "G".
      ..drawRect(
        Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke / 4, stroke),
        Paint()..color = _blue,
      );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
