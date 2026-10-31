/// Form validators. Each returns a [FieldError] code, or null if the value
/// is valid; the UI turns the code into text in the active language
/// (`AppLocalizations.fieldError`), so `core` stays free of UI strings.
library;

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
final _digit = RegExp(r'\d');

const passwordMinLength = 8;
const passwordMaxLength = 128;
const nameMaxLength = 50;

enum FieldError {
  emailRequired,
  emailInvalid,
  passwordRequired,
  passwordTooShort,
  passwordTooLong,
  passwordLettersDigits,
  confirmRequired,
  passwordMismatch,
  firstNameRequired,
  lastNameRequired,
  nameTooLong,
  samePassword,
}

/// A business rule broken in a repository call. Still an [ArgumentError],
/// so existing `on ArgumentError` handlers keep catching it.
class FieldErrorException extends ArgumentError {
  FieldErrorException(this.error) : super(error.name);

  final FieldError error;
}

enum NameField { first, last }

/// Emails are stored and compared trimmed and lowercase.
String normalizeEmail(String email) => email.trim().toLowerCase();

FieldError? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return FieldError.emailRequired;
  if (!_emailPattern.hasMatch(v)) return FieldError.emailInvalid;
  return null;
}

FieldError? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return FieldError.passwordRequired;
  if (v.length < passwordMinLength) return FieldError.passwordTooShort;
  if (v.length > passwordMaxLength) return FieldError.passwordTooLong;
  if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) {
    return FieldError.passwordLettersDigits;
  }
  return null;
}

FieldError? validatePasswordConfirmation(String? value, String password) {
  if ((value ?? '').isEmpty) return FieldError.confirmRequired;
  if (value != password) return FieldError.passwordMismatch;
  return null;
}

FieldError? validateName(String? value, {required NameField field}) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) {
    return field == NameField.first
        ? FieldError.firstNameRequired
        : FieldError.lastNameRequired;
  }
  if (v.length > nameMaxLength) return FieldError.nameTooLong;
  return null;
}

/// Optional free text: trimmed, null when empty, cut at [max] characters
/// (the forms already stop at [max]; this guards other callers).
String? trimmedOrNull(String? s, int max) {
  final t = s?.trim() ?? '';
  if (t.isEmpty) return null;
  return t.length > max ? t.substring(0, max) : t;
}
