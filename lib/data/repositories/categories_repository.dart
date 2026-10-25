import '../../core/category_icons.dart';
import '../database.dart';
import '../models/category.dart';

const categoryNameMaxLength = 30;

/// The category still has expenses: they must go to another one first.
class CategoryInUseException implements Exception {
  const CategoryInUseException(this.expenses);

  final int expenses;
}

/// The user's own categories (base ones are read only). Every query is
/// scoped by `user_id`; an expense never ends up without a category.
class CategoriesRepository {
  CategoriesRepository(this._db);

  final AppDatabase _db;

  /// Base and own, alphabetically, "Otros" last.
  Future<List<Category>> list(int userId) async {
    final rows = await _db.db.query(
      'categories',
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [userId],
      orderBy: "name = 'Otros', name COLLATE NOCASE",
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category> create(int userId, Category category) async {
    final c = await _validated(userId, category, exceptId: null);
    final id = await _db.db.insert(
      'categories',
      (c.toMap()..remove('id'))..['user_id'] = userId,
    );
    return (await _own(userId, id))!;
  }

  Future<Category> update(int userId, Category category) async {
    if (await _own(userId, category.id!) == null) {
      throw StateError('Categoría no encontrada');
    }
    final c = await _validated(userId, category, exceptId: category.id);
    await _db.db.update(
      'categories',
      {'name': c.name, 'icon': c.icon, 'color': c.color},
      where: 'id = ? AND user_id = ?',
      whereArgs: [c.id, userId],
    );
    return (await _own(userId, c.id!))!;
  }

  /// Expenses of the user in [categoryId].
  Future<int> expenseCount(int userId, int categoryId) async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS n FROM expenses WHERE user_id = ? AND category_id = ?',
      [userId, categoryId],
    );
    return rows.single['n']! as int;
  }

  /// Deletes an own category. With expenses, [reassignTo] (a base or own
  /// category) is required: they move there in the same transaction.
  /// Throws [CategoryInUseException] when it is missing.
  Future<void> delete(int userId, int categoryId, {int? reassignTo}) async {
    await _db.db.transaction((txn) async {
      final own = await txn.query(
        'categories',
        where: 'id = ? AND user_id = ?',
        whereArgs: [categoryId, userId],
        limit: 1,
      );
      if (own.isEmpty) throw StateError('Categoría no encontrada');
      final count =
          (await txn.rawQuery(
                'SELECT COUNT(*) AS n FROM expenses '
                'WHERE user_id = ? AND category_id = ?',
                [userId, categoryId],
              )).single['n']!
              as int;
      if (count > 0) {
        if (reassignTo == null) throw CategoryInUseException(count);
        if (reassignTo == categoryId) {
          throw ArgumentError('Elige otra categoría');
        }
        final target = await txn.query(
          'categories',
          where: 'id = ? AND (user_id IS NULL OR user_id = ?)',
          whereArgs: [reassignTo, userId],
          limit: 1,
        );
        if (target.isEmpty) throw StateError('Categoría no encontrada');
        await txn.update(
          'expenses',
          {'category_id': reassignTo},
          where: 'user_id = ? AND category_id = ?',
          whereArgs: [userId, categoryId],
        );
      }
      await txn.delete(
        'categories',
        where: 'id = ? AND user_id = ?',
        whereArgs: [categoryId, userId],
      );
    });
  }

  Future<Category?> _own(int userId, int id) async {
    final rows = await _db.db.query(
      'categories',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Category.fromMap(rows.single);
  }

  /// Name 1–30 characters, unique (any case) among the base categories
  /// and the user's own; icon and color from the offered sets.
  Future<Category> _validated(
    int userId,
    Category c, {
    required int? exceptId,
  }) async {
    final name = c.name.trim();
    if (name.isEmpty) throw ArgumentError('Escribe un nombre');
    if (name.length > categoryNameMaxLength) {
      throw ArgumentError('Máximo $categoryNameMaxLength caracteres');
    }
    if (!categoryIcons.containsKey(c.icon)) {
      throw ArgumentError('Ícono no válido');
    }
    if (!categoryColors.contains(c.color)) {
      throw ArgumentError('Color no válido');
    }
    final clash = await _db.db.query(
      'categories',
      where:
          '(user_id IS NULL OR user_id = ?) AND name = ? COLLATE NOCASE'
          '${exceptId == null ? '' : ' AND id != ?'}',
      whereArgs: [userId, name, ?exceptId],
      limit: 1,
    );
    if (clash.isNotEmpty) throw ArgumentError('Ya tienes una categoría así');
    return c.copyWith(name: name);
  }
}
