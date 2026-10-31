import 'package:flutter/widgets.dart';

import '../core/language.dart';
import '../core/security_question.dart';
import '../core/validators.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// The texts in the active language.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The texts in [language], for code without a [BuildContext] (e.g. the
/// biometric prompt reason).
AppLocalizations l10nFor(AppLanguage language) =>
    lookupAppLocalizations(Locale(language.code));

extension FieldErrorText on AppLocalizations {
  /// The message for a validation error, or null when there is none, so it
  /// plugs into `TextFormField.validator`.
  String? fieldError(FieldError? error) => switch (error) {
    null => null,
    FieldError.emailRequired => fieldEmailRequired,
    FieldError.emailInvalid => fieldEmailInvalid,
    FieldError.passwordRequired => fieldPasswordRequired,
    FieldError.passwordTooShort => fieldPasswordTooShort(passwordMinLength),
    FieldError.passwordTooLong => fieldTooLong(passwordMaxLength),
    FieldError.passwordLettersDigits => fieldPasswordLettersDigits,
    FieldError.confirmRequired => fieldConfirmRequired,
    FieldError.passwordMismatch => fieldPasswordMismatch,
    FieldError.firstNameRequired => fieldFirstNameRequired,
    FieldError.lastNameRequired => fieldLastNameRequired,
    FieldError.nameTooLong => fieldTooLong(nameMaxLength),
    FieldError.samePassword => fieldSamePassword,
    FieldError.questionRequired => fieldQuestionRequired,
    FieldError.questionTooLong => fieldTooLong(
      SecurityQuestion.customMaxLength,
    ),
    FieldError.answerRequired => fieldAnswerRequired,
    FieldError.answerTooShort => fieldAnswerTooShort(securityAnswerMinLength),
    FieldError.answerTooLong => fieldTooLong(securityAnswerMaxLength),
  };
}

extension SecurityQuestionText on AppLocalizations {
  /// A list question in the active language, or the user's own text.
  String securityQuestionText(SecurityQuestion question) => switch (question) {
    CustomQuestion(:final text) => text,
    PresetQuestion(:final preset) => switch (preset) {
      SecurityQuestionPreset.firstPet => secQFirstPet,
      SecurityQuestionPreset.birthCity => secQBirthCity,
      SecurityQuestionPreset.primarySchool => secQPrimarySchool,
      SecurityQuestionPreset.childhoodFriend => secQChildhoodFriend,
      SecurityQuestionPreset.firstJob => secQFirstJob,
    },
  };
}
