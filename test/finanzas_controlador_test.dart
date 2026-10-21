import 'package:app_financiera/datos/repositorio_finanzas.dart';
import 'package:app_financiera/dominio/modelos.dart';
import 'package:app_financiera/estado/finanzas_controlador.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio falso en memoria: permite probar el controlador sin red.
class _RepoFalso implements RepositorioFinanzas {
  int cargas = 0;
  final decisiones = <String, bool>{};
  ErrorApi? fallo;

  @override
  Future<IngresoRegistrado> registrarIngreso(int monto, String descripcion) async {
    if (fallo != null) throw fallo!;
    return IngresoRegistrado(
      id: 'i1',
      monto: monto,
      descripcion: descripcion,
      reparto: Reparto(
        necesidades: monto ~/ 2,
        inversion: monto ~/ 4,
        estabilidad: monto * 15 ~/ 100,
        entretenimiento: monto ~/ 10,
      ),
    );
  }

  @override
  Future<void> registrarGasto(int m, Categoria c, String d) async {}

  @override
  Future<List<Confirmacion>> confirmacionesPendientes() async {
    cargas++;
    return [
      Confirmacion(
        id: 'c1',
        categoria: Categoria.inversion,
        monto: 187500,
        creadoEn: DateTime(2026, 10, 21),
      ),
    ];
  }

  @override
  Future<void> decidir(String id, {required bool confirmar}) async {
    decisiones[id] = confirmar;
  }

  @override
  Future<Resumen> resumen({String? mes}) async =>
      const Resumen(ingresosTotal: 0, gastosTotal: 0, categorias: []);

  @override
  Future<List<Movimiento>> movimientos() async => const [];

  @override
  Future<void> eliminarMovimiento(String id) async {}
}

void main() {
  test('cargar trae resumen, movimientos y pendientes', () async {
    final c = FinanzasControlador(_RepoFalso());
    await c.cargar();
    expect(c.resumen, isNotNull);
    expect(c.pendientes, hasLength(1));
    expect(c.cargando, isFalse);
  });

  test('un monto en cero se rechaza sin llamar al servidor', () async {
    final repo = _RepoFalso();
    final c = FinanzasControlador(repo);
    final r = await c.registrarIngreso(0, 'x');
    expect(r, isNull);
    expect(c.error, 'El monto debe ser mayor a cero.');
    expect(repo.cargas, 0);
  });

  test('registrar un ingreso devuelve el reparto y recarga los datos', () async {
    final repo = _RepoFalso();
    final c = FinanzasControlador(repo);
    final r = await c.registrarIngreso(750000, 'Sueldo');
    expect(r, isNotNull);
    expect(r!.reparto.necesidades, 375000);
    expect(repo.cargas, 1);
    expect(c.error, isNull);
  });

  test('si la API falla, muestra el error y no recarga', () async {
    final repo = _RepoFalso()..fallo = const ErrorApi(503, 'Servicio no disponible');
    final c = FinanzasControlador(repo);
    final r = await c.registrarIngreso(1000, 'x');
    expect(r, isNull);
    expect(c.error, 'Servicio no disponible');
    expect(c.ocupado, isFalse);
  });

  test('confirmar o rechazar envía la decisión correcta', () async {
    final repo = _RepoFalso();
    final c = FinanzasControlador(repo);
    await c.cargar();
    await c.decidir(c.pendientes.first, confirmar: false);
    expect(repo.decisiones['c1'], isFalse);
  });
}
