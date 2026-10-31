import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Picks a list question (by its preset name, any language) and types the
/// answer in a SecurityQuestionFields with [prefix].
Future<void> pickSecurityQuestion(
  WidgetTester tester,
  String prefix, {
  String preset = 'birthCity',
  String answer = 'Santo Domingo',
}) async {
  final dropdown = find.byKey(ValueKey('$prefix.securityQuestion'));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(ValueKey('$prefix.securityQuestion.$preset')).last,
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(ValueKey('$prefix.securityAnswer')),
    answer,
  );
}
