import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/language.dart';

/// The three ARB files stay in step: same keys, no empty texts, and the
/// same `{placeholders}` as the Spanish template.
void main() {
  Map<String, String> texts(AppLanguage l) {
    final json = jsonDecode(
      File('lib/l10n/app_${l.code}.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    return {
      for (final e in json.entries)
        if (!e.key.startsWith('@')) e.key: e.value as String,
    };
  }

  /// `{name}` placeholders; ICU plural branches are skipped.
  Set<String> placeholders(String text) => {
    for (final m in RegExp(r'\{(\w+)[},]').allMatches(text)) m.group(1)!,
  };

  final es = texts(AppLanguage.es);

  for (final language in AppLanguage.values.where((l) => l != AppLanguage.es)) {
    test('${language.code} has every Spanish key, filled in', () {
      final other = texts(language);
      expect(other.keys.toSet(), es.keys.toSet());
      for (final key in es.keys) {
        expect(other[key]!.trim(), isNotEmpty, reason: key);
        expect(
          placeholders(other[key]!),
          placeholders(es[key]!),
          reason: '$key placeholders',
        );
      }
    });
  }

  // A `\$` copied from Dart source would show up as a literal backslash.
  for (final language in AppLanguage.values) {
    test('${language.code} texts have no stray backslashes', () {
      for (final MapEntry(:key, :value) in texts(language).entries) {
        expect(value, isNot(contains(r'\')), reason: key);
      }
    });
  }
}
