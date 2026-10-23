import '../../core/money.dart';
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
      throw ArgumentError(
        'Esta tarjeta tiene movimientos en ${dropped.join(' y ')}; '
        'no puedes quitar esa moneda',
      );
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
    if (alias.isEmpty) throw ArgumentError('Escribe un nombre para la tarjeta');
    if (bank.isEmpty) throw ArgumentError('Escribe el banco');
    if (!_last4Pattern.hasMatch(card.last4)) {
      throw ArgumentError('Escribe los últimos 4 dígitos');
    }
    if (card.cutDay < 1 || card.cutDay > 31) {
      throw ArgumentError('El día de corte va del 1 al 31');
    }
    if (card.paymentDays < 0 || card.paymentDays > 60) {
      throw ArgumentError('Los días para pagar van de 0 a 60');
    }
    if (card.creditLimitCents < 0 || card.secondaryLimitCents < 0) {
      throw ArgumentError('Límite no válido');
    }
    if (card.dualCurrency && card.currency != Currency.dop) {
      throw ArgumentError('Una tarjeta de doble balance es RD\$ y US\$');
    }
    return card.copyWith(
      alias: alias,
      bank: bank,
      // Only dual cards have a second (US$) limit.
      secondaryLimitCents: card.dualCurrency ? card.secondaryLimitCents : 0,
    );
  }
}
