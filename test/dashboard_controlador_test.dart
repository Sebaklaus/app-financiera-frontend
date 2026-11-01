import 'package:app_financiera/datos/repositorio_dashboard.dart';
import 'package:app_financiera/dominio/modelos.dart';
import 'package:app_financiera/estado/dashboard_controlador.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';

MesTendencia _mes(String mes, int ingresos, int gastos, [Map<Categoria, int>? porCategoria]) =>
    MesTendencia(
      mes: mes,
      ingresos: ingresos,
      gastos: gastos,
      balance: ingresos - gastos,
      gastosPorCategoria: {
        for (final c in Categoria.values) c: porCategoria?[c] ?? 0,
      },
    );

class _RepoFalso implements RepositorioDashboard {
  _RepoFalso(this.meses);

  List<MesTendencia> meses;
  ErrorApi? fallo;

  @override
  Future<List<MesTendencia>> tendencia({int meses = 6}) async {
    if (fallo != null) throw fallo!;
    return this.meses;
  }
}

void main() {
  test('sin movimientos no hay datos que graficar', () async {
    final c = DashboardControlador(_RepoFalso([_mes('2026-09', 0, 0), _mes('2026-10', 0, 0)]));
    await c.cargar();
    expect(c.hayDatos, isFalse);
    expect(c.maximo, 0);
    expect(c.gastosDelMes, isEmpty);
  });

  test('el máximo toma el valor más alto de ingresos y gastos', () async {
    final c = DashboardControlador(_RepoFalso([
      _mes('2026-08', 100000, 40000),
      _mes('2026-09', 80000, 150000),
      _mes('2026-10', 200000, 20000),
    ]));
    await c.cargar();
    expect(c.hayDatos, isTrue);
    expect(c.maximo, 200000);
    expect(c.actual!.mes, '2026-10');
  });

  test('los gastos del mes salen ordenados de mayor a menor y sin ceros', () async {
    final c = DashboardControlador(_RepoFalso([
      _mes('2026-10', 100000, 60000, {
        Categoria.entretenimiento: 10000,
        Categoria.necesidades: 50000,
      }),
    ]));
    await c.cargar();
    final lista = c.gastosDelMes;
    expect(lista.map((e) => e.key), [Categoria.necesidades, Categoria.entretenimiento]);
    expect(lista.first.value, 50000);
  });

  test('un error del servidor se muestra y no deja datos viejos rotos', () async {
    final repo = _RepoFalso([_mes('2026-10', 1000, 500)]);
    final c = DashboardControlador(repo);
    await c.cargar();
    repo.fallo = const ErrorApi(null, 'No se pudo conectar con el servidor.');
    await c.cargar();
    expect(c.error, 'No se pudo conectar con el servidor.');
    expect(c.cargando, isFalse);
  });

  test('MesTendencia.fromJson lee categorías y calcula la etiqueta del mes', () {
    final m = MesTendencia.fromJson({
      'mes': '2026-10',
      'ingresos': 300000,
      'gastos': 90000,
      'balance': 210000,
      'gastos_por_categoria': {'necesidades': 70000, 'entretenimiento': 20000},
    });
    expect(m.etiqueta, 'oct');
    expect(m.gastosPorCategoria[Categoria.necesidades], 70000);
    expect(m.gastosPorCategoria[Categoria.inversion], 0);
    expect(_mes('raro', 0, 0).etiqueta, 'raro');
  });
}
