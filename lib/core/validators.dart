/// Form validators. Each returns an error message in Spanish, or null if the
/// value is valid, so they plug directly into `TextFormField.validator`.
library;

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
final _digit = RegExp(r'\d');

const passwordMinLength = 8;
const passwordMaxLength = 128;
const nameMaxLength = 50;

/// Emails are stored and compared trimmed and lowercase.
String normalizeEmail(String email) => email.trim().toLowerCase();

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Escribe tu correo';
  if (!_emailPattern.hasMatch(v)) return 'Correo no válido';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Escribe tu contraseña';
  if (v.length < passwordMinLength) {
    return 'Mínimo $passwordMinLength caracteres';
  }
  if (v.length > passwordMaxLength) {
    return 'Máximo $passwordMaxLength caracteres';
  }
  if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) {
    return 'Debe tener letras y números';
  }
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if ((value ?? '').isEmpty) return 'Confirma tu contraseña';
  if (value != password) return 'Las contraseñas no coinciden';
  return null;
}

String? validateName(String? value, {required String field}) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Escribe tu $field';
  if (v.length > nameMaxLength) return 'Máximo $nameMaxLength caracteres';
  return null;
}

/// Optional free text: trimmed, null when empty, cut at [max] characters
/// (the forms already stop at [max]; this guards other callers).
String? trimmedOrNull(String? s, int max) {
  final t = s?.trim() ?? '';
  if (t.isEmpty) return null;
  return t.length > max ? t.substring(0, max) : t;
}
