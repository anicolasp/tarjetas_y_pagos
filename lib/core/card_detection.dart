/// Reads card data out of OCR text: the number (to validate it and get the
/// last 4 and the brand) and the bank. Pure functions; the full number never
/// leaves [detectCard].
library;

import '../data/models/credit_card.dart';
import 'banks.dart';

/// What a card photo told us. Any field may be missing.
class CardDetection {
  const CardDetection({this.last4, this.brand, this.bank});

  final String? last4;
  final CardBrand? brand;

  /// One of [dominicanBanks].
  final String? bank;

  bool get isEmpty => last4 == null && brand == null && bank == null;
}

/// Luhn checksum over a string of digits.
bool luhnValid(String digits) {
  if (!RegExp(r'^\d+$').hasMatch(digits)) return false;
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var d = digits.codeUnitAt(digits.length - 1 - i) - 0x30;
    if (i.isOdd) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 == 0;
}

/// Brand by BIN: 4 = Visa; 51–55 or 2221–2720 = Mastercard; 34/37 = Amex.
CardBrand brandFor(String digits) {
  if (digits.startsWith('4')) return CardBrand.visa;
  if (digits.length >= 2) {
    final two = int.parse(digits.substring(0, 2));
    if (two >= 51 && two <= 55) return CardBrand.mastercard;
    if (two == 34 || two == 37) return CardBrand.amex;
  }
  if (digits.length >= 4) {
    final four = int.parse(digits.substring(0, 4));
    if (four >= 2221 && four <= 2720) return CardBrand.mastercard;
  }
  return CardBrand.other;
}

const _accents = {
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', //
};

/// Lowercase, without accents and with words separated by single spaces.
String _normalize(String text) {
  final lower = text.toLowerCase().split('').map((c) => _accents[c] ?? c);
  return lower.join().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// The bank named in [text], matching whole words in any case and with or
/// without accents. The longest alias wins.
String? bankIn(String text) {
  final haystack = ' ${_normalize(text)} ';
  String? best;
  var bestLength = 0;
  for (final MapEntry(key: bank, value: aliases) in bankAliases.entries) {
    for (final alias in aliases) {
      if (alias.length > bestLength && haystack.contains(' $alias ')) {
        best = bank;
        bestLength = alias.length;
      }
    }
  }
  return best;
}

/// Digits with optional single spaces, dashes or line breaks between them
/// (ML Kit often returns embossed 4-4-4-4 groups on separate lines).
final _digitRun = RegExp(r'\d+(?:(?:[ \t-]|\r?\n)\d+)*');

/// Real card lengths first, so stray digits next to a 16-digit number
/// (a code, part of a date) are not glued on just because Luhn passes.
const _lengthPreference = [16, 15, 19, 14, 13, 17, 18];

/// The first card number in [text]: 13–19 digits passing Luhn, made of
/// whole printed groups, preferring common lengths and earlier groups.
String? _cardNumberIn(String text) {
  for (final run in _digitRun.allMatches(text)) {
    final groups = run.group(0)!.split(RegExp(r'[ \t-]|\r?\n'));
    String? best;
    var bestRank = _lengthPreference.length;
    for (var start = 0; start < groups.length; start++) {
      var digits = '';
      for (var end = start; end < groups.length; end++) {
        digits += groups[end];
        if (digits.length > 19) break;
        final rank = _lengthPreference.indexOf(digits.length);
        if (rank >= 0 && rank < bestRank && luhnValid(digits)) {
          best = digits;
          bestRank = rank;
        }
      }
    }
    if (best != null) return best;
  }
  return null;
}

/// Card data in OCR [text]. Only the last 4 digits come out.
CardDetection detectCard(String text) {
  final number = _cardNumberIn(text);
  return CardDetection(
    last4: number?.substring(number.length - 4),
    // An unknown BIN says nothing: keep whatever brand the user chose.
    brand: switch (number) {
      null => null,
      _ when brandFor(number) == CardBrand.other => null,
      _ => brandFor(number),
    },
    bank: bankIn(text),
  );
}
