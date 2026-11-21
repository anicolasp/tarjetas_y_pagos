import 'package:flutter/widgets.dart';

import '../core/formatters.dart';
import '../core/greeting.dart';
import '../core/language.dart';
import '../core/money.dart';
import '../core/report.dart' show ReportPeriod;
import '../core/security_question.dart';
import '../core/validators.dart';
import '../data/models/category.dart';
import '../data/models/credit_card.dart';
import '../data/repositories/categories_repository.dart'
    show categoryNameMaxLength;
import '../data/repositories/debts_repository.dart' show creditorMaxLength;
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
    FieldError.creditorRequired => fieldCreditorRequired,
    FieldError.creditorTooLong => fieldTooLong(creditorMaxLength),
    FieldError.debtCurrencyLocked => fieldDebtCurrencyLocked,
    FieldError.debtAmountBelowPaid => fieldDebtAmountBelowPaid,
    FieldError.dateTooOld => fieldDateTooOld,
    FieldError.paymentAboveRemaining => fieldPaymentAboveRemaining,
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

  String reportPeriod(ReportPeriod period) => switch (period) {
    ReportPeriod.thisMonth => periodThisMonth,
    ReportPeriod.lastMonth => periodLastMonth,
    ReportPeriod.last3Months => periodLast3Months,
    ReportPeriod.custom => periodCustom,
  };

  /// [categories] in alphabetical order of their shown names, "Otros"
  /// last. The repository sorts by the stored (Spanish) names, which is
  /// not alphabetical once translated.
  List<Category> sortedCategories(Iterable<Category> categories) {
    int rank(Category c) => c.isBase && c.name == 'Otros' ? 1 : 0;
    // Without accents and case: "Électricité" sorts with the E's.
    String sortKey(Category c) => normalizeSecurityAnswer(categoryLabel(c));
    return [...categories]..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : sortKey(a).compareTo(sortKey(b));
    });
  }
}

/// Amounts as a screen reader should say them (#40).
extension SpokenMoney on AppLocalizations {
  /// `RD$ 1,250.50` → "1250 pesos dominicanos con 50 centavos". The number
  /// has no thousands commas: Spanish and French voices would read them as
  /// decimals.
  String moneySemantics(int cents, Currency currency) {
    final whole = cents.abs() ~/ 100;
    final rest = cents.abs() % 100;
    final units = switch (currency) {
      Currency.dop => spokenPesos(whole, '$whole'),
      Currency.usd => spokenDollars(whole, '$whole'),
    };
    final amount = rest == 0
        ? units
        : spokenWithCents(units, spokenCents(rest));
    return cents < 0 ? spokenMinus(amount) : amount;
  }

  /// "Visa ending in 4 3 2 1": the last 4 digit by digit, not "four
  /// thousand…".
  String spokenCardEnding(CreditCard card) => cardEndingIn(
    card.brand == CardBrand.other ? cardOtherBrand : card.brand.label,
    card.last4.split('').join(' '),
  );

  /// [text] with every formatted amount in it spoken ([moneySemantics]),
  /// for `Text.semanticsLabel`. Null when [text] has no amount, so the
  /// text is read as it is.
  String? speakMoney(String text) {
    final spoken = text.replaceAllMapped(formattedMoney, (m) {
      final (:cents, :currency) = parseFormattedMoney(m);
      return moneySemantics(cents, currency);
    });
    return identical(spoken, text) || spoken == text ? null : spoken;
  }
}

/// A [Text] whose amounts a screen reader says in words ([speakMoney]),
/// e.g. "1250 pesos dominicanos" instead of "R D dollar 1,250.00" (#40).
/// It is a plain [Text]: same look, same widget type.
Text spokenText(
  BuildContext context,
  String data, {
  Key? key,
  TextStyle? style,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
  bool? softWrap,
}) => Text(
  data,
  key: key,
  style: style,
  textAlign: textAlign,
  maxLines: maxLines,
  overflow: overflow,
  softWrap: softWrap,
  semanticsLabel: context.l10n.speakMoney(data),
);
