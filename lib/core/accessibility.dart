import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Text size chosen in Mi perfil (#38). [factor] multiplies the phone's own
/// text size, never replaces it.
enum TextSize {
  normal(1),
  large(1.25),
  xlarge(1.5);

  const TextSize(this.factor);

  final double factor;

  /// [name] when known, else [normal].
  static TextSize fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => normal);
}

/// The largest text scale the app's own size setting can reach (the phone
/// times [TextSize.factor]); past it some screens become unusable.
const maxTextScale = 3.0;

/// The lowest in-app brightness (#39): the screen never goes black.
const minAppBrightness = 0.1;

/// A user's accessibility settings (#38, #39), applied on top of the
/// phone's.
@immutable
class A11ySettings {
  const A11ySettings({
    this.textSize = TextSize.normal,
    this.legibleFont = false,
    this.boldText = false,
    this.highContrast = false,
    this.brightness,
  });

  final TextSize textSize;
  final bool legibleFont;
  final bool boldText;
  final bool highContrast;

  /// The app's own screen brightness (0.1–1) while it is open; null uses
  /// the phone's. Never changes the phone's setting (#39).
  final double? brightness;

  /// From the `users` columns (v6, v7).
  factory A11ySettings.fromColumns(Map<String, Object?> m) => A11ySettings(
    textSize: TextSize.fromName(m['text_size'] as String?),
    legibleFont: m['legible_font'] == 1,
    boldText: m['bold_text'] == 1,
    highContrast: m['high_contrast'] == 1,
    brightness: _validBrightness((m['app_brightness'] as num?)?.toDouble()),
  );

  /// The `users` columns (v6, v7).
  Map<String, Object?> toColumns() => {
    'text_size': textSize.name,
    'legible_font': legibleFont ? 1 : 0,
    'bold_text': boldText ? 1 : 0,
    'high_contrast': highContrast ? 1 : 0,
    'app_brightness': brightness,
  };

  /// One string, so the pre-login copy is always saved whole. The
  /// brightness is last and empty when it follows the phone.
  String encode() => [
    textSize.name,
    for (final on in [legibleFont, boldText, highContrast]) on ? '1' : '0',
    brightness?.toString() ?? '',
  ].join(',');

  /// [encode]'s output, also the 4-field one from before #39; anything else
  /// gives the defaults.
  static A11ySettings decode(String? value) {
    final parts = value?.split(',') ?? const [];
    if (parts.length != 4 && parts.length != 5) return const A11ySettings();
    return A11ySettings(
      textSize: TextSize.fromName(parts[0]),
      legibleFont: parts[1] == '1',
      boldText: parts[2] == '1',
      highContrast: parts[3] == '1',
      brightness: parts.length == 5
          ? _validBrightness(double.tryParse(parts[4]))
          : null,
    );
  }

  /// [brightness] is a getter so it can be set back to null (the phone's).
  A11ySettings copyWith({
    TextSize? textSize,
    bool? legibleFont,
    bool? boldText,
    bool? highContrast,
    ValueGetter<double?>? brightness,
  }) => A11ySettings(
    textSize: textSize ?? this.textSize,
    legibleFont: legibleFont ?? this.legibleFont,
    boldText: boldText ?? this.boldText,
    highContrast: highContrast ?? this.highContrast,
    brightness: brightness == null ? this.brightness : brightness(),
  );

  @override
  bool operator ==(Object other) =>
      other is A11ySettings &&
      other.textSize == textSize &&
      other.legibleFont == legibleFont &&
      other.boldText == boldText &&
      other.highContrast == highContrast &&
      other.brightness == brightness;

  @override
  int get hashCode =>
      Object.hash(textSize, legibleFont, boldText, highContrast, brightness);
}

/// [value] clamped to [minAppBrightness]–1; null when missing or invalid.
double? _validBrightness(double? value) =>
    value == null || value.isNaN ? null : value.clamp(minAppBrightness, 1);

/// The phone's [base] scaler times [factor], capped at [maxTextScale]. The
/// cap only limits what the app adds: a phone already past it keeps its own
/// size. Keeps the phone's nonlinear scaling (Android 14+).
class AppTextScaler extends TextScaler {
  const AppTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) {
    if (factor == 1) return base.scale(fontSize);
    final phone = base.scale(fontSize);
    final cap = math.max(phone, fontSize * maxTextScale);
    return math.min(base.scale(fontSize * factor), cap);
  }

  @Deprecated('Use scale instead.')
  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is AppTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

/// [settings] on top of the phone's [MediaQuery] for [child]: the text
/// scale and bold text. The font and contrast come through the theme.
class A11yMediaQuery extends StatelessWidget {
  const A11yMediaQuery({
    super.key,
    required this.settings,
    required this.child,
  });

  final A11ySettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: AppTextScaler(media.textScaler, settings.textSize.factor),
        // The phone's bold text always wins.
        boldText: media.boldText || settings.boldText,
      ),
      child: child,
    );
  }
}
