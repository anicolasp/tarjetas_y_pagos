import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/category_icons.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/category.dart';
import 'package:tarjetas_y_pagos/data/repositories/categories_repository.dart';

import '../helpers/seed.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late CategoriesRepository repo;
  late int ana;
  late int otro;
  late int cardId;

  setUp(() async {
    db = await openTestDatabase();
    repo = CategoriesRepository(db);
    ana = (await seedUser(db, email: 'ana@example.com')).id!;
    otro = (await seedUser(db, email: 'otro@example.com')).id!;
    cardId = (await seedCard(db, ana)).id!;
  });

  tearDown(() => db.close());

  Category draft(String name) =>
      Category(name: name, icon: 'pets', color: categoryColors.first);

  Future<int> idOf(String name) async =>
      (await repo.list(ana)).firstWhere((c) => c.name == name).id!;

  test('create: trimmed, owned, listed with the base ones', () async {
    final c = await repo.create(ana, draft('  Mascotas '));
    expect(c.name, 'Mascotas');
    expect(c.userId, ana);
    final names = (await repo.list(ana)).map((c) => c.name).toList();
    expect(names, contains('Mascotas'));
    expect(names.last, 'Otros');
    // Another user doesn't see it.
    expect(
      (await repo.list(otro)).map((c) => c.name),
      isNot(contains('Mascotas')),
    );
  });

  test('names are unique among base and own ones, in any case', () async {
    await repo.create(ana, draft('Mascotas'));
    expect(() => repo.create(ana, draft('mascotas')), throwsArgumentError);
    expect(() => repo.create(ana, draft('SUPERMERCADO')), throwsArgumentError);
    // Each user has their own namespace.
    expect((await repo.create(otro, draft('Mascotas'))).userId, otro);
  });

  test('uniqueness also ignores the case of accented letters', () async {
    await repo.create(ana, draft('Educación'));
    expect(() => repo.create(ana, draft('EDUCACIÓN')), throwsArgumentError);
  });

  test('the length counts characters, as the text field does', () async {
    // 20 emoji are 40 UTF-16 units but 20 characters.
    final c = await repo.create(ana, draft('🐶' * 20));
    expect(c.name, '🐶' * 20);
    expect(() => repo.create(ana, draft('🐱' * 31)), throwsArgumentError);
  });

  test('validation: name, icon and color', () async {
    expect(() => repo.create(ana, draft(' ')), throwsArgumentError);
    expect(() => repo.create(ana, draft('x' * 31)), throwsArgumentError);
    expect(
      () => repo.create(ana, draft('A').copyWith(icon: 'nope')),
      throwsArgumentError,
    );
    expect(
      () => repo.create(ana, draft('A').copyWith(color: 0xFF123456)),
      throwsArgumentError,
    );
  });

  test('update an own category; base ones are read only', () async {
    final c = await repo.create(ana, draft('Mascotas'));
    final u = await repo.update(
      ana,
      c.copyWith(name: 'Mis mascotas', icon: 'home'),
    );
    expect((u.name, u.icon), ('Mis mascotas', 'home'));
    final base = await idOf('Supermercado');
    expect(
      () => repo.update(ana, draft('X').copyWith(id: base)),
      throwsStateError,
    );
    // Renaming to its own name is fine.
    expect((await repo.update(ana, u)).name, 'Mis mascotas');
  });

  test(
    'a category with expenses cannot be deleted without reassigning',
    () async {
      final c = await repo.create(ana, draft('Mascotas'));
      await seedExpense(db, ana, cardId, 'Mascotas', 'Veterinaria Ficticia');
      await seedExpense(db, ana, cardId, 'Mascotas', 'Comida Ficticia');
      expect(await repo.expenseCount(ana, c.id!), 2);

      await expectLater(
        repo.delete(ana, c.id!),
        throwsA(
          isA<CategoryInUseException>().having((e) => e.expenses, 'n', 2),
        ),
      );
      expect((await repo.list(ana)).map((c) => c.name), contains('Mascotas'));

      final otros = await idOf('Otros');
      await repo.delete(ana, c.id!, reassignTo: otros);
      expect(
        (await repo.list(ana)).map((c) => c.name),
        isNot(contains('Mascotas')),
      );
      final rows = await db.db.query(
        'expenses',
        where: 'user_id = ?',
        whereArgs: [ana],
      );
      expect(rows.map((r) => r['category_id']), everyElement(otros));
    },
  );

  test('reassigning to itself or to someone else\'s category fails', () async {
    final c = await repo.create(ana, draft('Mascotas'));
    final theirs = await repo.create(otro, draft('Suya'));
    await seedExpense(db, ana, cardId, 'Mascotas', 'Veterinaria Ficticia');
    expect(
      () => repo.delete(ana, c.id!, reassignTo: c.id),
      throwsArgumentError,
    );
    expect(
      () => repo.delete(ana, c.id!, reassignTo: theirs.id),
      throwsStateError,
    );
    expect(await repo.expenseCount(ana, c.id!), 1);
  });

  test('without expenses it is deleted directly; base ones never', () async {
    final c = await repo.create(ana, draft('Mascotas'));
    await repo.delete(ana, c.id!);
    expect(
      (await repo.list(ana)).map((c) => c.name),
      isNot(contains('Mascotas')),
    );
    final otros = await idOf('Otros');
    expect(() => repo.delete(ana, otros), throwsStateError);
  });

  test('another user cannot touch my categories', () async {
    final c = await repo.create(ana, draft('Mascotas'));
    expect(() => repo.update(otro, c.copyWith(name: 'X')), throwsStateError);
    expect(() => repo.delete(otro, c.id!), throwsStateError);
  });
}
