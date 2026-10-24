import '../../core/billing_cycle.dart';
import '../../core/money.dart';
import '../../core/report.dart';
import '../database.dart';
import '../models/card_payment.dart';
import '../models/category.dart';
import '../models/credit_card.dart';
import '../models/db_codec.dart';
import '../models/expense.dart';
import '../../core/validators.dart';

const merchantMaxLength = 80;
const notesMaxLength = 200;

/// Expense search. Every field is optional; dates and amounts are inclusive.
class ExpenseFilter {
  const ExpenseFilter({
    this.cardId,
    this.cardIds = const {},
    this.categoryIds = const {},
    this.from,
    this.to,
    this.merchant,
    this.minCents,
    this.maxCents,
  });

  /// One card (card detail).
  final int? cardId;

  /// Any of these cards (reports). Empty: every card.
  final Set<int> cardIds;
  final Set<int> categoryIds;
  final DateTime? from;
  final DateTime? to;

  /// Case-insensitive "contains" on the merchant name.
  final String? merchant;
  final int? minCents;
  final int? maxCents;

  /// True when only the card is set (no user-chosen criteria).
  bool get isEmpty =>
      categoryIds.isEmpty &&
      from == null &&
      to == null &&
      (merchant ?? '').trim().isEmpty &&
      minCents == null &&
      maxCents == null;

  ExpenseFilter cleared() => ExpenseFilter(cardId: cardId, cardIds: cardIds);

  /// A copy with some fields changed. Nullable fields take a function so
  /// they can also be cleared: `copyWith(merchant: () => null)`.
  ExpenseFilter copyWith({
    int? Function()? cardId,
    Set<int>? cardIds,
    Set<int>? categoryIds,
    DateTime? Function()? from,
    DateTime? Function()? to,
    String? Function()? merchant,
    int? Function()? minCents,
    int? Function()? maxCents,
  }) => ExpenseFilter(
    cardId: cardId == null ? this.cardId : cardId(),
    cardIds: cardIds ?? this.cardIds,
    categoryIds: categoryIds ?? this.categoryIds,
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
    merchant: merchant == null ? this.merchant : merchant(),
    minCents: minCents == null ? this.minCents : minCents(),
    maxCents: maxCents == null ? this.maxCents : maxCents(),
  );

  @override
  bool operator ==(Object other) =>
      other is ExpenseFilter &&
      other.cardId == cardId &&
      other.cardIds.length == cardIds.length &&
      other.cardIds.containsAll(cardIds) &&
      other.categoryIds.length == categoryIds.length &&
      other.categoryIds.containsAll(categoryIds) &&
      other.from == from &&
      other.to == to &&
      other.merchant == merchant &&
      other.minCents == minCents &&
      other.maxCents == maxCents;

  @override
  int get hashCode => Object.hash(
    cardId,
    Object.hashAllUnordered(cardIds),
    Object.hashAllUnordered(categoryIds),
    from,
    to,
    merchant,
    minCents,
    maxCents,
  );
}

/// Expenses and card payments of one user. Every query is scoped by
/// `user_id` (payments through their card).
class ExpensesRepository {
  ExpensesRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  // ---------------------------------------------------------------- read

  /// The SQL condition for [filter], always scoped to [userId]. Shared by
  /// the list and the report so both see exactly the same expenses.
  static ({String where, List<Object?> args}) _whereFor(
    int userId,
    ExpenseFilter filter,
  ) {
    final where = ['user_id = ?'];
    final args = <Object?>[userId];
    void inList(String column, Set<int> ids) {
      where.add('$column IN (${List.filled(ids.length, '?').join(', ')})');
      args.addAll(ids);
    }

    if (filter.cardId != null) {
      where.add('card_id = ?');
      args.add(filter.cardId);
    }
    if (filter.cardIds.isNotEmpty) inList('card_id', filter.cardIds);
    if (filter.categoryIds.isNotEmpty) {
      inList('category_id', filter.categoryIds);
    }
    if (filter.from != null) {
      where.add('date >= ?');
      args.add(encodeDate(filter.from!));
    }
    if (filter.to != null) {
      where.add('date <= ?');
      args.add(encodeDate(filter.to!));
    }
    final merchant = filter.merchant?.trim() ?? '';
    if (merchant.isNotEmpty) {
      // Escape LIKE wildcards so "50%" matches literally.
      final escaped = merchant
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      where.add(r"merchant LIKE ? ESCAPE '\'");
      args.add('%$escaped%');
    }
    if (filter.minCents != null) {
      where.add('amount_cents >= ?');
      args.add(filter.minCents);
    }
    if (filter.maxCents != null) {
      where.add('amount_cents <= ?');
      args.add(filter.maxCents);
    }
    return (where: where.join(' AND '), args: args);
  }

  /// Newest first. Includes expenses of archived cards.
  Future<List<Expense>> list(
    int userId, [
    ExpenseFilter filter = const ExpenseFilter(),
  ]) async {
    final (:where, :args) = _whereFor(userId, filter);
    final rows = await _db.db.query(
      'expenses',
      where: where,
      whereArgs: args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  /// Totals per currency and per category, month and card for [filter],
  /// aggregated in SQL. Amounts are what was charged to each card (a
  /// converted expense counts in the card's currency).
  Future<ExpenseReport> report(
    int userId, [
    ExpenseFilter filter = const ExpenseFilter(),
  ]) async {
    final (:where, :args) = _whereFor(userId, filter);
    // One read transaction: every breakdown comes from the same snapshot,
    // so the totals always match the charts.
    final (byCategory, byMonth, byCard) = await _db.db.transaction((txn) async {
      Future<List<Map<String, Object?>>> grouped(String key) => txn.rawQuery(
        'SELECT $key AS k, currency, SUM(amount_cents) AS total, '
        'COUNT(*) AS n FROM expenses WHERE $where '
        'GROUP BY k, currency',
        args,
      );
      return (
        await grouped('category_id'),
        await grouped("strftime('%Y-%m', date)"),
        await grouped('card_id'),
      );
    });

    Currency currency(Map<String, Object?> r) =>
        Currency.fromCode(r['currency']! as String);
    int total(Map<String, Object?> r) => r['total']! as int;

    // Totals per currency are the sum of the per-category groups (every
    // expense has exactly one category).
    final totals = <Currency, ({int total, int count})>{};
    for (final r in byCategory) {
      final t = totals[currency(r)] ?? (total: 0, count: 0);
      totals[currency(r)] = (
        total: t.total + total(r),
        count: t.count + (r['n']! as int),
      );
    }

    return ExpenseReport(
      totals: {
        for (final MapEntry(key: c, value: t) in totals.entries)
          c: CurrencyTotals(currency: c, totalCents: t.total, count: t.count),
      },
      byCategory: [
        for (final r in byCategory)
          (
            categoryId: r['k']! as int,
            currency: currency(r),
            totalCents: total(r),
            count: r['n']! as int,
          ),
      ],
      byMonth: [
        for (final r in byMonth)
          (
            month: DateTime.parse('${r['k']! as String}-01'),
            currency: currency(r),
            totalCents: total(r),
          ),
      ],
      byCard: [
        for (final r in byCard)
          (cardId: r['k']! as int, currency: currency(r), totalCents: total(r)),
      ],
    );
  }

  Future<Expense?> getById(int userId, int id) async {
    final rows = await _db.db.query(
      'expenses',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Expense.fromMap(rows.single);
  }

  /// Base categories plus the user's own, alphabetically ("Otros" last).
  Future<List<Category>> categories(int userId) async {
    final rows = await _db.db.query(
      'categories',
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [userId],
      orderBy: "name = 'Otros', name COLLATE NOCASE",
    );
    return rows.map(Category.fromMap).toList();
  }

  /// Newest first; payments of every card of the user, or one card.
  Future<List<CardPayment>> payments(int userId, {int? cardId}) async {
    final rows = await _db.db.rawQuery(
      'SELECT p.* FROM card_payments p JOIN cards c ON c.id = p.card_id '
      'WHERE c.user_id = ?${cardId == null ? '' : ' AND p.card_id = ?'} '
      'ORDER BY p.date DESC, p.id DESC',
      [userId, ?cardId],
    );
    return rows.map(CardPayment.fromMap).toList();
  }

  // --------------------------------------------------------------- write

  /// Throws [ArgumentError] for invalid data.
  Future<Expense> create(Expense expense) async {
    final clean = await _validated(expense);
    final map = clean.toMap()
      ..remove('id')
      ..['created_at'] = encodeTimestamp(_clock());
    final id = await _db.db.insert('expenses', map);
    return (await getById(expense.userId, id))!;
  }

  /// Throws [ArgumentError] for invalid data and [StateError] if the
  /// expense does not exist for that user.
  Future<void> update(Expense expense) async {
    final clean = await _validated(expense);
    final count = await _db.db.update(
      'expenses',
      clean.toMap()
        ..remove('id')
        ..remove('user_id')
        ..remove('created_at'),
      where: 'id = ? AND user_id = ?',
      whereArgs: [expense.id, expense.userId],
    );
    if (count == 0) throw StateError('Gasto no encontrado');
  }

  Future<void> delete(int userId, int id) async {
    final count = await _db.db.delete(
      'expenses',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (count == 0) throw StateError('Gasto no encontrado');
  }

  /// Throws [ArgumentError] for invalid data.
  Future<CardPayment> addPayment(int userId, CardPayment payment) async {
    final card = await _activeCard(userId, payment.cardId);
    if (payment.amountCents <= 0) throw ArgumentError('Monto no válido');
    _checkNotFuture(payment.date);
    if (!card.currencies.contains(payment.currency)) {
      throw ArgumentError('La tarjeta no tiene balance en esa moneda');
    }
    final id = await _db.db.insert(
      'card_payments',
      (payment.toMap()..remove('id'))
        ..['note'] = trimmedOrNull(payment.note, notesMaxLength),
    );
    final rows = await _db.db.query(
      'card_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    return CardPayment.fromMap(rows.single);
  }

  Future<void> deletePayment(int userId, int paymentId) async {
    final count = await _db.db.delete(
      'card_payments',
      where: 'id = ? AND card_id IN (SELECT id FROM cards WHERE user_id = ?)',
      whereArgs: [paymentId, userId],
    );
    if (count == 0) throw StateError('Pago no encontrado');
  }

  // ---------------------------------------------------------- validation

  Future<Expense> _validated(Expense e) async {
    final merchant = e.merchant.trim();
    if (merchant.isEmpty) throw ArgumentError('Escribe el comercio');
    if (merchant.length > merchantMaxLength) {
      throw ArgumentError('Máximo $merchantMaxLength caracteres');
    }
    if (e.amountCents <= 0) throw ArgumentError('Monto no válido');
    _checkNotFuture(e.date);

    final card = await _activeCard(e.userId, e.cardId);
    if (!card.currencies.contains(e.currency)) {
      throw ArgumentError('La tarjeta no tiene balance en esa moneda');
    }
    // A conversion records what was paid, in another currency, and the
    // rate; otherwise none of the three is set.
    final conversion = [
      e.originalAmountCents,
      e.originalCurrency,
      e.exchangeRateMicros,
    ];
    if (conversion.any((x) => x != null)) {
      if (conversion.any((x) => x == null) ||
          e.originalCurrency == e.currency ||
          e.originalAmountCents! <= 0 ||
          e.exchangeRateMicros! <= 0) {
        throw ArgumentError('Conversión no válida');
      }
    }

    final category = await _db.db.query(
      'categories',
      where: 'id = ? AND (user_id IS NULL OR user_id = ?)',
      whereArgs: [e.categoryId, e.userId],
      limit: 1,
    );
    if (category.isEmpty) throw ArgumentError('Elige una categoría');

    return e.copyWith(
      merchant: merchant,
      notes: trimmedOrNull(e.notes, notesMaxLength),
      clearNotes: trimmedOrNull(e.notes, notesMaxLength) == null,
    );
  }

  Future<CreditCard> _activeCard(int userId, int cardId) async {
    final rows = await _db.db.query(
      'cards',
      where: 'id = ? AND user_id = ? AND archived = 0',
      whereArgs: [cardId, userId],
      limit: 1,
    );
    if (rows.isEmpty) throw ArgumentError('Elige una tarjeta');
    return CreditCard.fromMap(rows.single);
  }

  void _checkNotFuture(DateTime date) {
    if (dateOnly(date).isAfter(dateOnly(_clock()))) {
      throw ArgumentError('La fecha no puede ser futura');
    }
  }
}
