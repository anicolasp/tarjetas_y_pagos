import 'package:local_auth/local_auth.dart';

abstract interface class BiometricService {
  /// True if the device has biometric hardware with something enrolled.
  Future<bool> isAvailable();

  /// Shows the system prompt. False if it fails, is cancelled or unavailable.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on Exception {
      return false;
    }
  }
}
