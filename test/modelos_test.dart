import 'package:app_financiera/dominio/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Reparto lee los cuatro montos y suma el total', () {
    final r = Reparto.fromJson({
      'necesidades': 375000,
      'inversion': 187500,
      'estabilidad': 112500,
      'entretenimiento': 75000,
    });
    expect(r.de(Categoria.inversion), 187500);
    expect(r.total, 750000);
  });

  test('solo inversión y estabilidad requieren confirmación', () {
    final requieren = Categoria.values
        .where((c) => c.requiereConfirmacion)
        .map((c) => c.clave)
        .toSet();
    expect(requieren, {'inversion', 'estabilidad'});
    expect(Categoria.values.fold<int>(0, (s, c) => s + c.porcentaje), 100);
  });

  test('Movimiento sin categoría (ingreso) se lee bien', () {
    final m = Movimiento.fromJson({
      'id': 'a',
      'tipo': 'ingreso',
      'monto': 750000,
      'categoria': null,
      'descripcion': 'Sueldo',
      'fecha': '2026-10-13',
    });
    expect(m.esIngreso, isTrue);
    expect(m.categoria, isNull);
  });

  test('Resumen lee las categorías', () {
    final r = Resumen.fromJson({
      'ingresos_total': 100,
      'gastos_total': 10,
      'categorias': [
        {
          'categoria': 'necesidades',
          'asignado': 50,
          'gastado': 10,
          'disponible': 40,
          'por_confirmar': 0,
          'rechazado': 0,
        }
      ],
    });
    expect(r.categorias.single.disponible, 40);
  });

  test('EstadoConsentimientos detecta pendientes', () {
    final e = EstadoConsentimientos.fromJson({
      'consentimientos': [
        {'tipo': 'terminos_y_privacidad', 'otorgado': true},
        {'tipo': 'datos_financieros', 'otorgado': false},
      ],
      'pendientes': ['datos_financieros'],
    });
    expect(e.completo, isFalse);
    expect(e.otorgados['terminos_y_privacidad'], isTrue);
  });
}
