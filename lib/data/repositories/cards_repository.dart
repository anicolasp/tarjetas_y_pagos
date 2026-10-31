import '../../core/money.dart';
import '../../core/validators.dart';
import '../database.dart';
import '../models/credit_card.dart';
import '../models/db_codec.dart';

final _last4Pattern = RegExp(r'^\d{4}$');

/// Credit cards of one user. Every query is scoped by `user_id`.
class CardsRepository {
  CardsRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  Future<List<CreditCard>> listActive(int userId) async {
    final rows = await _db.db.query(
      'cards',
      where: 'user_id = ? AND archived = 0',
      whereArgs: [userId],
      orderBy: 'created_at, id',
    );
    return rows.map(CreditCard.fromMap).toList();
  }

  /// Active and archived: reports still name the card of old expenses.
  Future<List<CreditCard>> listAll(int userId) async {
    final rows = await _db.db.query(
      'cards',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at, id',
    );
    return rows.map(CreditCard.fromMap).toList();
  }

  Future<CreditCard?> getById(int userId, int id) async {
    final rows = await _db.db.query(
      'cards',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : CreditCard.fromMap(rows.single);
  }

  /// Throws [ArgumentError] for invalid data.
  Future<CreditCard> create(CreditCard card) async {
    final map = _validated(card).toMap()
      ..remove('id')
      ..['archived'] = 0
      ..['created_at'] = encodeTimestamp(_clock());
    final id = await _db.db.insert('cards', map);
    return (await getById(card.userId, id))!;
  }

  /// Throws [ArgumentError] for invalid data and [StateError] if the card
  /// does not exist for that user.
  Future<void> update(CreditCard card) async {
    final clean = _validated(card);
    // A currency with expenses or payments cannot be dropped (changing the
    // currency, or turning dual off): that balance could never be paid.
    final used = await _db.db.rawQuery(
      'SELECT currency FROM expenses WHERE card_id = ? '
      'UNION SELECT currency FROM card_payments WHERE card_id = ?',
      [card.id, card.id],
    );
    final dropped = [
      for (final row in used)
        if (!clean.currencies.contains(
          Currency.fromCode(row['currency'] as String),
        ))
          row['currency'] as String,
    ];
    if (dropped.isNotEmpty) {
      // Its movements in that currency would be left without a balance.
      throw FieldErrorException(FieldError.cardCurrencyInUse);
    }
    final count = await _db.db.update(
      'cards',
      clean.toMap()
        ..remove('id')
        ..remove('user_id')
        ..remove('created_at'),
      where: 'id = ? AND user_id = ?',
      whereArgs: [card.id, card.userId],
    );
    if (count == 0) throw StateError('Tarjeta no encontrada');
  }

  /// Hides the card from lists and the ranking; its data is kept.
  Future<void> archive(int userId, int id) async {
    final count = await _db.db.update(
      'cards',
      {'archived': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (count == 0) throw StateError('Tarjeta no encontrada');
  }

  CreditCard _validated(CreditCard card) {
    final alias = card.alias.trim();
    final bank = card.bank.trim();
    if (alias.isEmpty) throw FieldErrorException(FieldError.cardAliasRequired);
    if (bank.isEmpty) throw FieldErrorException(FieldError.cardBankRequired);
    if (!_last4Pattern.hasMatch(card.last4)) {
      throw FieldErrorException(FieldError.cardLast4Invalid);
    }
    if (card.cutDay < 1 || card.cutDay > 31) {
      throw FieldErrorException(FieldError.cardCutDayRange);
    }
    if (card.paymentDays < 0 || card.paymentDays > 60) {
      throw FieldErrorException(FieldError.cardPaymentDaysRange);
    }
    if (card.creditLimitCents < 0 || card.secondaryLimitCents < 0) {
      throw FieldErrorException(FieldError.cardLimitInvalid);
    }
    if (card.dualCurrency && card.currency != Currency.dop) {
      throw FieldErrorException(FieldError.cardDualMustBeDop);
    }
    return card.copyWith(
      alias: alias,
      bank: bank,
      // Only dual cards have a second (US$) limit.
      secondaryLimitCents: card.dualCurrency ? card.secondaryLimitCents : 0,
    );
  }
}
