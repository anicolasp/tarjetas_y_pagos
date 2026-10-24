import 'package:sqflite/sqflite.dart';

import '../../core/billing_cycle.dart';
import '../database.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';

const creditorMaxLength = 80;
const debtDescriptionMaxLength = 200;
const debtNoteMaxLength = 200;

/// Debts outside the cards and their payments (abonos). Every query is
/// scoped by `user_id` (payments through their debt). The status follows
/// the payments: `saldada` exactly when nothing is left to pay.
class DebtsRepository {
  DebtsRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  // ---------------------------------------------------------------- read

  /// Oldest due date first; debts without one last.
  Future<List<Debt>> list(int userId) async {
    final rows = await _db.db.query(
      'debts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'due_date IS NULL, due_date, id',
    );
    return rows.map(Debt.fromMap).toList();
  }

  Future<Debt?> getById(int userId, int id) async {
    final rows = await _db.db.query(
      'debts',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Debt.fromMap(rows.single);
  }

  /// All payments of the user's debts, newest first.
  Future<List<DebtPayment>> payments(int userId) async {
    final rows = await _db.db.rawQuery(
      'SELECT p.* FROM debt_payments p JOIN debts d ON d.id = p.debt_id '
      'WHERE d.user_id = ? ORDER BY p.date DESC, p.id DESC',
      [userId],
    );
    return rows.map(DebtPayment.fromMap).toList();
  }

  // --------------------------------------------------------------- write

  Future<Debt> create(Debt debt) async {
    final d = _validated(debt);
    final id = await _db.db.insert(
      'debts',
      (d.toMap()..remove('id'))..['status'] = DebtStatus.active.dbValue,
    );
    return (await getById(d.userId, id))!;
  }

  /// The amount can't go below what was already paid; the status follows.
  Future<Debt> update(Debt debt) async {
    final d = _validated(debt);
    await _db.db.transaction((txn) async {
      await _owned(txn, d.userId, d.id!);
      final paid = await _paid(txn, d.id!);
      if (d.amountCents < paid) {
        throw ArgumentError('El monto no puede ser menor que lo ya abonado');
      }
      await txn.update(
        'debts',
        (d.toMap()
            ..remove('id')
            ..remove('user_id')
            ..remove('created_at'))
          ..['status'] = _statusFor(d.amountCents, paid).dbValue,
        where: 'id = ? AND user_id = ?',
        whereArgs: [d.id, d.userId],
      );
    });
    return (await getById(d.userId, d.id!))!;
  }

  /// Also deletes its payments (ON DELETE CASCADE).
  Future<void> delete(int userId, int debtId) async {
    final count = await _db.db.delete(
      'debts',
      where: 'id = ? AND user_id = ?',
      whereArgs: [debtId, userId],
    );
    if (count == 0) throw StateError('Deuda no encontrada');
  }

  /// A payment greater than what is left is rejected; reaching 0 settles
  /// the debt. Both happen in one transaction.
  Future<DebtPayment> addPayment(int userId, DebtPayment payment) async {
    if (payment.amountCents <= 0) throw ArgumentError('Monto no válido');
    final day = dateOnly(payment.date);
    if (day.isAfter(dateOnly(_clock()))) {
      throw ArgumentError('La fecha no puede ser futura');
    }
    final id = await _db.db.transaction((txn) async {
      final debt = await _owned(txn, userId, payment.debtId);
      if (day.isBefore(dateOnly(debt.createdAt))) {
        throw ArgumentError('La fecha es anterior a la deuda');
      }
      final paid = await _paid(txn, debt.id!);
      final remaining = debt.amountCents - paid;
      if (payment.amountCents > remaining) {
        throw ArgumentError('El abono es mayor que lo que falta por pagar');
      }
      final id = await txn.insert(
        'debt_payments',
        (payment.toMap()..remove('id'))
          ..['note'] = _trimmedOrNull(payment.note, debtNoteMaxLength),
      );
      await _setStatus(
        txn,
        debt.id!,
        _statusFor(debt.amountCents, paid + payment.amountCents),
      );
      return id;
    });
    final rows = await _db.db.query(
      'debt_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    return DebtPayment.fromMap(rows.single);
  }

  /// A settled debt with a payment removed is active again.
  Future<void> deletePayment(int userId, int paymentId) async {
    await _db.db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT p.debt_id FROM debt_payments p JOIN debts d '
        'ON d.id = p.debt_id WHERE p.id = ? AND d.user_id = ?',
        [paymentId, userId],
      );
      if (rows.isEmpty) throw StateError('Abono no encontrado');
      final debtId = rows.single['debt_id']! as int;
      await txn.delete(
        'debt_payments',
        where: 'id = ?',
        whereArgs: [paymentId],
      );
      final debt = await _owned(txn, userId, debtId);
      await _setStatus(
        txn,
        debtId,
        _statusFor(debt.amountCents, await _paid(txn, debtId)),
      );
    });
  }

  // ------------------------------------------------------------- helpers

  Debt _validated(Debt d) {
    final creditor = d.creditor.trim();
    if (creditor.isEmpty) throw ArgumentError('Escribe el acreedor');
    if (creditor.length > creditorMaxLength) {
      throw ArgumentError('Máximo $creditorMaxLength caracteres');
    }
    if (d.amountCents <= 0) throw ArgumentError('Monto no válido');
    final description = _trimmedOrNull(d.description, debtDescriptionMaxLength);
    return d.copyWith(
      creditor: creditor,
      description: description,
      clearDescription: description == null,
    );
  }

  static String? _trimmedOrNull(String? s, int max) {
    final t = s?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.length > max) throw ArgumentError('Máximo $max caracteres');
    return t;
  }

  static DebtStatus _statusFor(int amountCents, int paidCents) =>
      paidCents >= amountCents ? DebtStatus.settled : DebtStatus.active;

  static Future<Debt> _owned(Transaction txn, int userId, int debtId) async {
    final rows = await txn.query(
      'debts',
      where: 'id = ? AND user_id = ?',
      whereArgs: [debtId, userId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Deuda no encontrada');
    return Debt.fromMap(rows.single);
  }

  static Future<int> _paid(Transaction txn, int debtId) async {
    final rows = await txn.rawQuery(
      'SELECT COALESCE(SUM(amount_cents), 0) AS paid FROM debt_payments '
      'WHERE debt_id = ?',
      [debtId],
    );
    return rows.single['paid']! as int;
  }

  static Future<void> _setStatus(
    Transaction txn,
    int debtId,
    DebtStatus status,
  ) => txn.update(
    'debts',
    {'status': status.dbValue},
    where: 'id = ?',
    whereArgs: [debtId],
  );
}
