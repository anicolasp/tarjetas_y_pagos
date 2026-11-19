import 'package:flutter/material.dart' show ThemeMode;

import '../../core/accessibility.dart';
import '../../core/language.dart';
import '../../core/money.dart';
import '../../core/security_question.dart';
import 'db_codec.dart';

class AppUser {
  const AppUser({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.biometricEnabled = false,
    this.themeMode = ThemeMode.system,
    this.defaultCurrency = Currency.dop,
    this.notifyDaysBefore = 3,
    this.language = AppLanguage.es,
    this.securityQuestion,
    this.googleSub,
    this.a11y = const A11ySettings(),
    required this.createdAt,
  });

  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;
  final String salt;
  final bool biometricEnabled;
  final ThemeMode themeMode;
  final Currency defaultCurrency;
  final int notifyDaysBefore;
  final AppLanguage language;

  /// Null for accounts created before #27. The answer never leaves the
  /// repository.
  final SecurityQuestion? securityQuestion;

  bool get hasSecurityQuestion => securityQuestion != null;

  /// Google's id for the linked account (#37); null when not linked.
  final String? googleSub;

  bool get hasGoogle => googleSub != null;

  /// False for an account created with Google that has not set one: its
  /// hash and salt are stored empty.
  bool get hasPassword => passwordHash.isNotEmpty;

  /// Text size, legible font, bold and high contrast (#38).
  final A11ySettings a11y;
  final DateTime createdAt;

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
    id: m['id'] as int?,
    firstName: m['first_name'] as String,
    lastName: m['last_name'] as String,
    email: m['email'] as String,
    passwordHash: m['password_hash'] as String,
    salt: m['salt'] as String,
    biometricEnabled: decodeBool(m['biometric_enabled']),
    themeMode: ThemeMode.values.byName(m['theme_mode'] as String),
    defaultCurrency: Currency.fromCode(m['default_currency'] as String),
    notifyDaysBefore: m['notify_days_before'] as int,
    language: AppLanguage.fromCode(m['language'] as String?),
    securityQuestion: SecurityQuestion.decode(
      m['security_question'] as String?,
    ),
    googleSub: m['google_sub'] as String?,
    a11y: A11ySettings(
      textSize: TextSize.fromName(m['text_size'] as String?),
      legibleFont: decodeBool(m['legible_font']),
      boldText: decodeBool(m['bold_text']),
      highContrast: decodeBool(m['high_contrast']),
    ),
    createdAt: decodeTimestamp(m['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'password_hash': passwordHash,
    'salt': salt,
    'biometric_enabled': encodeBool(biometricEnabled),
    'theme_mode': themeMode.name,
    'default_currency': defaultCurrency.code,
    'notify_days_before': notifyDaysBefore,
    'language': language.code,
    'security_question': securityQuestion?.encode(),
    'google_sub': googleSub,
    'text_size': a11y.textSize.name,
    'legible_font': encodeBool(a11y.legibleFont),
    'bold_text': encodeBool(a11y.boldText),
    'high_contrast': encodeBool(a11y.highContrast),
    'created_at': encodeTimestamp(createdAt),
  };

  AppUser copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? passwordHash,
    String? salt,
    bool? biometricEnabled,
    ThemeMode? themeMode,
    Currency? defaultCurrency,
    int? notifyDaysBefore,
    AppLanguage? language,
    SecurityQuestion? securityQuestion,
    String? googleSub,
    A11ySettings? a11y,
  }) => AppUser(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    themeMode: themeMode ?? this.themeMode,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
    language: language ?? this.language,
    securityQuestion: securityQuestion ?? this.securityQuestion,
    googleSub: googleSub ?? this.googleSub,
    a11y: a11y ?? this.a11y,
    createdAt: createdAt,
  );
}
