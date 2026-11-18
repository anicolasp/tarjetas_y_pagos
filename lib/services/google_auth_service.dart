import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

/// Who Google says the user is. Only [sub] (Google's id for the account)
/// and [email] are kept; no token is ever stored.
typedef GoogleIdentity = ({String sub, String email, String? name});

enum GoogleSignInFailure {
  /// Google could not be reached or did not finish (no connection, Play
  /// services busy…). Trying again may work.
  failed,

  /// The app is not set up for Google (wrong client id or SHA-1): a
  /// developer problem, not the user's.
  misconfigured,
}

class GoogleSignInFailedException implements Exception {
  const GoogleSignInFailedException(this.failure);

  final GoogleSignInFailure failure;
}

/// Sign in with Google (#37). Only Android is set up.
abstract interface class GoogleAuthService {
  /// False without a Web client id (`GOOGLE_SERVER_CLIENT_ID` in
  /// `dart_defines.local.json`) or off Android: the button is hidden.
  bool get available;

  /// The chosen account, or null if the user closed Google's sheet.
  /// Throws [GoogleSignInFailedException].
  Future<GoogleIdentity?> signIn();

  /// Forgets the account in the app, so the next sign in lets the user
  /// pick one. Never throws.
  Future<void> signOut();
}

class PluginGoogleAuthService implements GoogleAuthService {
  PluginGoogleAuthService({
    this.serverClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ),
  });

  /// The Web client id: Android needs it to identify the account.
  final String serverClientId;

  Future<void>? _initialized;

  @override
  bool get available => serverClientId.isNotEmpty && Platform.isAndroid;

  /// Once per app run; a failed attempt is retried on the next call.
  Future<void> _init() => _initialized ??= GoogleSignIn.instance
      .initialize(serverClientId: serverClientId)
      .catchError((Object e) {
        _initialized = null;
        throw e;
      });

  @override
  Future<GoogleIdentity?> signIn() async {
    try {
      await _init();
      final account = await GoogleSignIn.instance.authenticate();
      return (sub: account.id, email: account.email, name: account.displayName);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleSignInFailedException(switch (e.code) {
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          GoogleSignInFailure.misconfigured,
        _ => GoogleSignInFailure.failed,
      });
    } on Object {
      // Anything else from the platform or the plugin: the user still gets
      // a message.
      throw const GoogleSignInFailedException(GoogleSignInFailure.failed);
    }
  }

  @override
  Future<void> signOut() async {
    if (!available) return;
    try {
      await _init();
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Nothing to undo: the app session is already closed.
    }
  }
}
