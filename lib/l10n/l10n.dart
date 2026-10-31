import 'package:flutter/widgets.dart';

import '../core/greeting.dart';
import '../core/language.dart';
import '../core/security_question.dart';
import '../core/validators.dart';
import '../data/database.dart' show baseCategories;
import '../data/models/category.dart';
import '../data/repositories/categories_repository.dart'
    show categoryNameMaxLength;
import '../data/repositories/expenses_repository.dart' show merchantMaxLength;
import '../services/receipt_ai_service.dart' show ReceiptScanError;
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
    FieldError.cardAliasRequired => fieldCardAliasRequired,
    FieldError.cardBankRequired => fieldCardBankRequired,
    FieldError.cardLast4Invalid => fieldCardLast4Invalid,
    FieldError.cardCutDayRange => fieldCardCutDayRange,
    FieldError.cardPaymentDaysRange => fieldCardPaymentDaysRange,
    FieldError.cardLimitInvalid => fieldCardLimitInvalid,
    FieldError.cardDualMustBeDop => fieldCardDualMustBeDop,
    FieldError.cardCurrencyInUse => fieldCardCurrencyInUse,
    FieldError.amountInvalid => fieldAmountInvalid,
    FieldError.noBalanceInCurrency => fieldNoBalanceInCurrency,
    FieldError.merchantRequired => fieldMerchantRequired,
    FieldError.merchantTooLong => fieldTooLong(merchantMaxLength),
    FieldError.conversionInvalid => fieldConversionInvalid,
    FieldError.categoryRequired => fieldCategoryRequired,
    FieldError.cardRequired => fieldCardRequired,
    FieldError.dateInFuture => fieldDateInFuture,
    FieldError.categoryNameRequired => fieldCategoryNameRequired,
    FieldError.categoryNameTooLong => fieldTooLong(categoryNameMaxLength),
    FieldError.categoryIconInvalid => fieldCategoryIconInvalid,
    FieldError.categoryColorInvalid => fieldCategoryColorInvalid,
    FieldError.categoryNameTaken => fieldCategoryNameTaken,
    FieldError.categoryReassignOther => fieldCategoryReassignOther,
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

extension AppTexts on AppLocalizations {
  /// "Buenos días, Ana".
  String greeting(DayPart part, String name) => switch (part) {
    DayPart.morning => greetingMorning(name),
    DayPart.afternoon => greetingAfternoon(name),
    DayPart.night => greetingNight(name),
  };

  String receiptScanError(ReceiptScanError error) => switch (error) {
    ReceiptScanError.offline => receiptErrorOffline,
    ReceiptScanError.timeout => receiptErrorTimeout,
    ReceiptScanError.invalidKey => receiptErrorInvalidKey,
    ReceiptScanError.rateLimited => receiptErrorRateLimited,
    ReceiptScanError.unavailable => receiptErrorUnavailable,
    ReceiptScanError.imageTooLarge => receiptErrorImageTooLarge,
    ReceiptScanError.invalidResponse => receiptErrorInvalidResponse,
  };

  /// A category as shown: the 13 base ones in the active language (they are
  /// stored in Spanish, `baseCategories`); the user's own as written.
  String categoryLabel(Category category) {
    if (!category.isBase) return category.name;
    return switch (category.name) {
      'Supermercado' => catSupermarket,
      'Combustible' => catFuel,
      'Barbería' => catBarbershop,
      'Salón' => catSalon,
      'Belleza' => catBeauty,
      'Ferretería' => catHardware,
      'Luz' => catElectricity,
      'Agua' => catWater,
      'Teléfono' => catPhone,
      'Licor' => catLiquor,
      'Salud' => catHealth,
      'Restaurante' => catRestaurant,
      'Otros' => catOther,
      _ => category.name,
    };
  }
}

/// Every base category has a translation (checked by a test).
Iterable<String> get baseCategoryNames => baseCategories.map((c) => c.name);
