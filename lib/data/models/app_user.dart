import 'package:flutter/material.dart' show ThemeMode;

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
    createdAt: createdAt,
  );
}
