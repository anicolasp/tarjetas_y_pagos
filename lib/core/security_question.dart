/// Security questions for password recovery (#27): one of the [presets]
/// (its text is translated) or a question the user wrote.
library;

/// The questions offered in the list. Their texts live in the ARB files.
enum SecurityQuestionPreset {
  firstPet,
  birthCity,
  primarySchool,
  childhoodFriend,
  firstJob,
}

/// What is stored in `users.security_question`: `preset:<name>` for a list
/// question, or the text the user wrote.
sealed class SecurityQuestion {
  const SecurityQuestion();

  static const _prefix = 'preset:';
  static const customMaxLength = 100;

  /// Null when the column is null (account without a question).
  static SecurityQuestion? decode(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (stored.startsWith(_prefix)) {
      final name = stored.substring(_prefix.length);
      for (final p in SecurityQuestionPreset.values) {
        if (p.name == name) return PresetQuestion(p);
      }
    }
    return CustomQuestion(stored);
  }

  String encode();
}

class PresetQuestion extends SecurityQuestion {
  const PresetQuestion(this.preset);

  final SecurityQuestionPreset preset;

  @override
  String encode() => '${SecurityQuestion._prefix}${preset.name}';

  @override
  bool operator ==(Object other) =>
      other is PresetQuestion && other.preset == preset;

  @override
  int get hashCode => preset.hashCode;
}

class CustomQuestion extends SecurityQuestion {
  const CustomQuestion(this.text);

  final String text;

  @override
  String encode() => text.trim();

  @override
  bool operator ==(Object other) =>
      other is CustomQuestion && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

const securityAnswerMinLength = 3;
const securityAnswerMaxLength = 100;

const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// The answer as compared: trimmed, single spaces, lowercase, without
/// accents. "Santo  Domingo" and "santo domingo" are the same answer.
String normalizeSecurityAnswer(String answer) {
  final lower = answer.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    out.write(_accents[ch] ?? ch);
  }
  return out.toString();
}
