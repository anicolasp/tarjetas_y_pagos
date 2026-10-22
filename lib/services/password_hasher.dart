import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// PBKDF2-HMAC-SHA256 password hashing.
///
/// Stored format: `pbkdf2-sha256$<iterations>$<base64 hash>`, with the salt in
/// its own column. Keeping the iteration count in the hash lets us raise it
/// later and re-hash on the next successful login ([needsRehash]).
class PasswordHasher {
  const PasswordHasher({
    this.iterations = defaultIterations,
    this.useIsolate = true,
  });

  /// OWASP 2023 recommendation for PBKDF2-HMAC-SHA256.
  static const defaultIterations = 210000;
  static const saltLength = 16;
  static const _scheme = 'pbkdf2-sha256';

  final int iterations;

  /// Derivation runs in a background isolate so the UI does not freeze.
  /// Widget tests turn it off because fake async cannot wait on isolates.
  final bool useIsolate;

  String newSalt() {
    final random = Random.secure();
    return base64Encode(
      List<int>.generate(saltLength, (_) => random.nextInt(256)),
    );
  }

  Future<String> hash(String password, String salt) async {
    final bytes = await _run(password, salt, iterations);
    return '$_scheme\$$iterations\$${base64Encode(bytes)}';
  }

  /// Compares in constant time. Returns false for malformed stored hashes.
  Future<bool> verify(String password, String salt, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 3 || parts[0] != _scheme) return false;
    final storedIterations = int.tryParse(parts[1]);
    if (storedIterations == null || storedIterations <= 0) return false;
    final expected = base64Decode(parts[2]);
    final actual = await _run(password, salt, storedIterations);
    return _constantTimeEquals(expected, actual);
  }

  bool needsRehash(String stored) {
    final parts = stored.split(r'$');
    return parts.length != 3 ||
        parts[0] != _scheme ||
        int.tryParse(parts[1]) != iterations;
  }

  Future<List<int>> _run(String password, String salt, int iterations) =>
      useIsolate
      ? Isolate.run(() => _derive(password, salt, iterations))
      : _derive(password, salt, iterations);
}

Future<List<int>> _derive(String password, String salt, int iterations) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );
  final key = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: base64Decode(salt),
  );
  return key.extractBytes();
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
