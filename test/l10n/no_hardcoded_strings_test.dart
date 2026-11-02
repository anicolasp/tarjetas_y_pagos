import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every visible text comes from the ARB files (#29). The scan reads the
/// source of `lib/` (not the generated `lib/l10n/`) and fails on:
///
/// 1. a literal with words where the UI shows text: `Text('…')`,
///    `labelText: '…'`, `tooltip: '…'`…;
/// 2. any literal with Spanish characters (á, ñ, ¿…), wherever it is;
/// 3. a repository rule thrown as `ArgumentError('…')` with text, or an
///    exception message shown as is (`e.message`).
///
/// The exceptions are data, not texts, and each one says why.
void main() {
  /// File → literals allowed in it.
  const allowed = <String, Set<String>>{
    // The brand: the same in every language (`appTitle` too).
    'lib/app.dart': {'Tarjetas y Pagos'},
    // Base categories are stored in Spanish and translated on display
    // (`categoryLabel`).
    'lib/data/database.dart': {'Barbería', 'Salón', 'Ferretería', 'Teléfono'},
    // Bank names are proper nouns, matched against the card photo.
    'lib/core/banks.dart': {'Banco López de Haro', 'Asociación Cibao'},
    // Each language is shown in its own language.
    'lib/core/language.dart': {'Español', 'Français'},
    // Card brands: the printed logos, and the name read out for the
    // Mastercard circles.
    'lib/features/cards/widgets/credit_card_tile.dart': {
      'VISA',
      'AMEX',
      'Mastercard',
    },
  };

  /// Files whose Spanish characters are code, not texts: the accent
  /// folding maps and the letter class of the password rule.
  const accentCode = {
    'lib/core/card_detection.dart',
    'lib/core/security_question.dart',
    'lib/core/validators.dart',
    // Matches the stored Spanish base names to their translations.
    'lib/l10n/l10n.dart',
  };

  // A one-line '…' or "…" literal.
  const quoted =
      r"'(?:[^'\\\n]|\\.)*'"
      '|'
      r'"(?:[^"\\\n]|\\.)*"';
  final visible = RegExp(
    r'(?:\bText\(\s*|\b(?:labelText|hintText|helperText|errorText|tooltip|'
    r'title|label|body|message|text|subtitle|semanticLabel|'
    r'semanticsLabel|prefixText|suffixText)\s*:\s*)(?<!r)('
    '$quoted)',
  );
  final literal = RegExp('(?<![r\\w])($quoted)');
  final spanish = RegExp('[áéíóúñÁÉÍÓÚÑ¿¡]');
  final thrownText = RegExp(r'''ArgumentError\(\s*['"]''');
  final shownMessage = RegExp(r'\be\.message\b');

  /// Without comments, so doc comments may quote Spanish texts.
  String code(String source) => source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'(^|\s)//.*$'), ''))
      .join('\n');

  /// The literal without quotes and interpolations: what a person reads.
  String words(String lit) => lit
      .substring(1, lit.length - 1)
      .replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');

  /// What [source] (the file at [path]) breaks, one line per finding.
  List<String> scan(String path, String source) {
    final found = <String>[];
    final ok = allowed[path] ?? const {};
    final clean = code(source);
    // On the whole file: `Text(` and its literal are often on two lines.
    for (final m in visible.allMatches(clean)) {
      final lit = m.group(1)!;
      // Two letters in a row: a word, not "•••• " or "−".
      if (RegExp(r'\p{L}{2}', unicode: true).hasMatch(words(lit)) &&
          !ok.contains(lit.substring(1, lit.length - 1))) {
        final line = '\n'.allMatches(clean.substring(0, m.start)).length + 1;
        found.add('$path:$line visible $lit');
      }
    }
    for (final (i, line) in clean.split('\n').indexed) {
      void flag(String why, String lit) {
        if (ok.contains(lit.substring(1, lit.length - 1))) return;
        found.add('$path:${i + 1} $why $lit');
      }

      if (!accentCode.contains(path)) {
        for (final m in literal.allMatches(line)) {
          final lit = m.group(1)!;
          if (spanish.hasMatch(words(lit))) flag('spanish', lit);
        }
      }
      if (thrownText.hasMatch(line)) found.add('$path:${i + 1} throw');
      if (path.startsWith('lib/features/') && shownMessage.hasMatch(line)) {
        found.add('$path:${i + 1} e.message');
      }
    }
    return found;
  }

  test('the scan catches each kind of hardcoded text', () {
    const sample = """
      Text('Hola'),
      TextField(decoration: InputDecoration(labelText: 'Monto')),
      final s = 'acción';
      throw ArgumentError('Monto no válido');
      showErrorSnackBar(context, '\${e.message}');
      // Text('in a comment'), ok
      Text(context.l10n.save), Text('\$amount'), Text('•••• \$last4'),
      Text(
        'Dos líneas',
      ),
    """;
    expect(
      scan('lib/features/x.dart', sample)..sort(),
      [
        "lib/features/x.dart:1 visible 'Hola'",
        "lib/features/x.dart:2 visible 'Monto'",
        "lib/features/x.dart:3 spanish 'acción'",
        "lib/features/x.dart:4 spanish 'Monto no válido'",
        'lib/features/x.dart:4 throw',
        'lib/features/x.dart:5 e.message',
        "lib/features/x.dart:8 visible 'Dos líneas'",
        "lib/features/x.dart:9 spanish 'Dos líneas'",
      ]..sort(),
    );
  });

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.startsWith('lib/l10n/app_localizations'))
      .toList();

  test('the scan sees the app', () => expect(files.length, greaterThan(50)));

  test('no visible text is written in the code', () {
    final found = [
      for (final f in files) ...scan(f.path, f.readAsStringSync()),
    ];
    expect(found, isEmpty, reason: 'Move these texts to the ARB files.');
  });
}
