import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/greeting.dart';

void main() {
  DateTime at(int h, int m) => DateTime(2026, 10, 22, h, m);

  test('greeting changes at 5:00, 12:00 and 19:00', () {
    expect(greetingFor(at(4, 59)), 'Buenas noches');
    expect(greetingFor(at(5, 0)), 'Buenos días');
    expect(greetingFor(at(11, 59)), 'Buenos días');
    expect(greetingFor(at(12, 0)), 'Buenas tardes');
    expect(greetingFor(at(18, 59)), 'Buenas tardes');
    expect(greetingFor(at(19, 0)), 'Buenas noches');
    expect(greetingFor(at(0, 0)), 'Buenas noches');
  });

  group('initialsOf', () {
    test('compound names use the first word of each', () {
      expect(initialsOf('María José', 'Pérez'), 'MP');
      expect(initialsOf('María José', 'Pérez Rodríguez'), 'MP');
    });
    test('keeps accents and upper-cases', () {
      expect(initialsOf('ángel', 'álvarez'), 'ÁÁ');
      expect(initialsOf('ñoño', 'útil'), 'ÑÚ');
    });
    test('trims and tolerates extra spaces', () {
      expect(initialsOf('  Ana  ', '  de la Cruz'), 'AD');
    });
    test('empty parts give what is available', () {
      expect(initialsOf('Ana', ''), 'A');
      expect(initialsOf('', ''), '');
    });
  });
}
