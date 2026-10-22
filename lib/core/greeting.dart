/// "Buenos días" 5:00–11:59, "Buenas tardes" 12:00–18:59, otherwise
/// "Buenas noches".
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Buenos días';
  if (h >= 12 && h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// First letter of the first given name and of the first surname, upper
/// case, accents kept: ("María José", "Pérez Rodríguez") → "MP".
String initialsOf(String firstName, String lastName) {
  String firstLetter(String s) {
    final word = s.trim().split(RegExp(r'\s+')).first;
    return word.isEmpty
        ? ''
        : String.fromCharCode(word.runes.first).toUpperCase();
  }

  return firstLetter(firstName) + firstLetter(lastName);
}
