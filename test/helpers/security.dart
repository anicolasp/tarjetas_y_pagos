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
  // On short screens the menu scrolls: bring the option into view first.
  final option = find.byKey(ValueKey('$prefix.securityQuestion.$preset'));
  if (option.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      option,
      40,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(option.last);
  await tester.pumpAndSettle();
  await tester.tap(option.last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(ValueKey('$prefix.securityAnswer')),
    answer,
  );
}
