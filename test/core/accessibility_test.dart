import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/accessibility.dart';

/// A phone with nonlinear scaling: small text grows more than big text.
class _Nonlinear extends TextScaler {
  const _Nonlinear();

  @override
  double scale(double fontSize) =>
      fontSize < 20 ? fontSize * 2 : fontSize * 1.5;

  @Deprecated('Use scale instead.')
  @override
  double get textScaleFactor => 2;
}

void main() {
  test('text size names round-trip; unknown ones are normal', () {
    for (final s in TextSize.values) {
      expect(TextSize.fromName(s.name), s);
    }
    expect(TextSize.fromName(null), TextSize.normal);
    expect(TextSize.fromName('huge'), TextSize.normal);
  });

  test('settings encode to one string and back; bad input is default', () {
    const all = A11ySettings(
      textSize: TextSize.large,
      legibleFont: true,
      highContrast: true,
    );
    expect(A11ySettings.decode(all.encode()), all);
    expect(
      A11ySettings.decode(const A11ySettings().encode()),
      const A11ySettings(),
    );
    expect(A11ySettings.decode(null), const A11ySettings());
    expect(A11ySettings.decode('xlarge,1'), const A11ySettings());
  });

  test('multiplies the phone size', () {
    const phone = TextScaler.linear(1.2);
    expect(const AppTextScaler(phone, 1).scale(10), closeTo(12, 1e-9));
    expect(const AppTextScaler(phone, 1.5).scale(10), closeTo(18, 1e-9));
  });

  test('caps what the app adds at x3', () {
    // Phone x2 by "Muy grande" x1.5 = x3, exactly the cap.
    expect(
      const AppTextScaler(TextScaler.linear(2), 1.5).scale(10),
      closeTo(30, 1e-9),
    );
    // Phone x2.5 by x1.5 = x3.75: capped.
    expect(
      const AppTextScaler(TextScaler.linear(2.5), 1.5).scale(10),
      closeTo(30, 1e-9),
    );
  });

  test('never makes text smaller than the phone asks for', () {
    // A phone past the cap keeps its own size.
    expect(
      const AppTextScaler(TextScaler.linear(3.5), 1.5).scale(10),
      closeTo(35, 1e-9),
    );
  });

  test("keeps the phone's nonlinear curve", () {
    const scaler = AppTextScaler(_Nonlinear(), 1.25);
    // 12 * 1.25 = 15 → x2 = 30 (cap 36).
    expect(scaler.scale(12), closeTo(30, 1e-9));
    // 20 * 1.25 = 25 → x1.5 = 37.5 (cap 60).
    expect(scaler.scale(20), closeTo(37.5, 1e-9));
  });

  testWidgets('A11yMediaQuery adds scale and bold, keeps the phone bold', (
    tester,
  ) async {
    late MediaQueryData seen;
    Widget probe(A11ySettings settings, {bool phoneBold = false}) => MediaQuery(
      data: MediaQueryData(boldText: phoneBold),
      child: A11yMediaQuery(
        settings: settings,
        child: Builder(
          builder: (context) {
            seen = MediaQuery.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpWidget(probe(const A11ySettings()));
    expect(seen.boldText, isFalse);
    expect(seen.textScaler.scale(10), 10);

    await tester.pumpWidget(
      probe(const A11ySettings(textSize: TextSize.large, boldText: true)),
    );
    expect(seen.boldText, isTrue);
    expect(seen.textScaler.scale(10), closeTo(12.5, 1e-9));

    await tester.pumpWidget(probe(const A11ySettings(), phoneBold: true));
    expect(seen.boldText, isTrue);
  });
}
