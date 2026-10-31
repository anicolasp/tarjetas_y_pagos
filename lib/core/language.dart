/// Languages the app is translated to. Adding one means adding its ARB file
/// in `lib/l10n/` and a value here.
enum AppLanguage {
  es('Español'),
  en('English'),
  fr('Français');

  const AppLanguage(this.nativeName);

  /// How the language calls itself; the selector shows it like this in
  /// every language.
  final String nativeName;

  /// The language code (`es`), as stored and as the Flutter locale.
  String get code => name;

  /// [code] when known, else Spanish (the app's original language).
  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => es);
}
