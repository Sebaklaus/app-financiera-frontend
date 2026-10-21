import 'package:app_financiera/nucleo/formato.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clp agrega puntos de miles', () {
    expect(clp(0), '\$0');
    expect(clp(999), '\$999');
    expect(clp(1000), '\$1.000');
    expect(clp(1234567), '\$1.234.567');
  });

  test('clp muestra el signo de los negativos', () {
    expect(clp(-45000), '-\$45.000');
  });

  test('parseMonto acepta puntos y rechaza texto sin dígitos', () {
    expect(parseMonto('1.500.000'), 1500000);
    expect(parseMonto('750000'), 750000);
    expect(parseMonto(''), isNull);
    expect(parseMonto('abc'), isNull);
  });

  test('fechaCorta invierte AAAA-MM-DD', () {
    expect(fechaCorta('2026-10-21'), '21-10-2026');
  });
}
