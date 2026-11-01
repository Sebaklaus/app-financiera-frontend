import 'package:app_financiera/datos/repositorio_metas.dart';
import 'package:app_financiera/dominio/modelos.dart';
import 'package:app_financiera/estado/metas_controlador.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoFalso implements RepositorioMetas {
  final List<MetaAhorro> _metas = [];
  final Map<String, List<AporteMeta>> _aportes = {};
  ErrorApi? fallo;
  int llamadas = 0;

  MetaAhorro _armar(String id) {
    final m = _metas.firstWhere((e) => e.id == id);
    final aportes = _aportes[id] ?? [];
    final total = aportes.fold(0, (s, a) => s + a.monto);
    return MetaAhorro(
      id: m.id,
      nombre: m.nombre,
      montoObjetivo: m.montoObjetivo,
      fechaLimite: m.fechaLimite,
      ahorrado: total,
      falta: total >= m.montoObjetivo ? 0 : m.montoObjetivo - total,
      porcentaje: (total * 100 ~/ m.montoObjetivo).clamp(0, 100),
      cumplida: total >= m.montoObjetivo,
      aportes: aportes,
    );
  }

  @override
  Future<List<MetaAhorro>> listar() async {
    llamadas++;
    if (fallo != null) throw fallo!;
    return [for (final m in _metas) _armar(m.id)];
  }

  @override
  Future<MetaAhorro> crear(String nombre, int montoObjetivo, String? fechaLimite) async {
    llamadas++;
    if (fallo != null) throw fallo!;
    final id = 'm${_metas.length + 1}';
    _metas.add(MetaAhorro(
      id: id,
      nombre: nombre,
      montoObjetivo: montoObjetivo,
      fechaLimite: fechaLimite,
      ahorrado: 0,
      falta: montoObjetivo,
      porcentaje: 0,
      cumplida: false,
    ));
    return _armar(id);
  }

  @override
  Future<MetaAhorro> detalle(String metaId) async => _armar(metaId);

  @override
  Future<MetaAhorro> aportar(String metaId, int monto, String? fecha) async {
    llamadas++;
    if (fallo != null) throw fallo!;
    (_aportes[metaId] ??= []).add(AporteMeta(id: 'a$llamadas', monto: monto, fecha: '2026-10-28'));
    return _armar(metaId);
  }

  @override
  Future<void> eliminar(String metaId) async {
    _metas.removeWhere((m) => m.id == metaId);
    _aportes.remove(metaId);
  }
}

void main() {
  test('cargar sin metas deja la lista vacía y sin error', () async {
    final c = MetasControlador(_RepoFalso());
    await c.cargar();
    expect(c.metas, isEmpty);
    expect(c.error, isNull);
    expect(c.cargando, isFalse);
  });

  test('una meta sin nombre o con monto cero no llama al servidor', () async {
    final repo = _RepoFalso();
    final c = MetasControlador(repo);
    expect(await c.crear('  ', 1000), isFalse);
    expect(c.error, contains('nombre'));
    expect(await c.crear('Viaje', 0), isFalse);
    expect(await c.crear('Viaje', null), isFalse);
    expect(repo.llamadas, 0);
  });

  test('crear agrega la meta con su avance en cero', () async {
    final c = MetasControlador(_RepoFalso());
    expect(await c.crear(' Viaje ', 500000, fechaLimite: '2026-12-31'), isTrue);
    expect(c.metas.single.nombre, 'Viaje');
    expect(c.metas.single.porcentaje, 0);
    expect(c.metas.single.fechaLimite, '2026-12-31');
  });

  test('aportar actualiza el avance y los totales', () async {
    final c = MetasControlador(_RepoFalso());
    await c.crear('Viaje', 500000);
    final id = c.metas.single.id;
    expect(await c.aportar(id, 125000), isTrue);
    expect(c.abierta!.ahorrado, 125000);
    expect(c.abierta!.porcentaje, 25);
    expect(c.metas.single.falta, 375000);
    expect(c.totalAhorrado, 125000);
    expect(c.cumplidas, 0);
  });

  test('llegar al objetivo marca la meta como cumplida', () async {
    final c = MetasControlador(_RepoFalso());
    await c.crear('Computador', 300000);
    final id = c.metas.single.id;
    await c.aportar(id, 300000);
    expect(c.metas.single.cumplida, isTrue);
    expect(c.metas.single.falta, 0);
    expect(c.cumplidas, 1);
  });

  test('un aporte de cero no llama al servidor', () async {
    final repo = _RepoFalso();
    final c = MetasControlador(repo);
    await c.crear('Viaje', 1000);
    final antes = repo.llamadas;
    expect(await c.aportar(c.metas.single.id, 0), isFalse);
    expect(c.error, isNotNull);
    expect(repo.llamadas, antes);
  });

  test('un error del servidor se muestra y no rompe la lista', () async {
    final repo = _RepoFalso();
    final c = MetasControlador(repo);
    await c.crear('Viaje', 1000);
    repo.fallo = const ErrorApi(422, 'La fecha límite no puede estar en el pasado');
    expect(await c.crear('Auto', 5000), isFalse);
    expect(c.error, 'La fecha límite no puede estar en el pasado');
    expect(c.metas, hasLength(1));
    expect(c.ocupado, isFalse);
  });

  test('eliminar quita la meta y cierra el detalle', () async {
    final c = MetasControlador(_RepoFalso());
    await c.crear('Viaje', 1000);
    final id = c.metas.single.id;
    await c.abrir(id);
    expect(c.abierta, isNotNull);
    expect(await c.eliminar(id), isTrue);
    expect(c.abierta, isNull);
    expect(c.metas, isEmpty);
  });

  test('MetaAhorro.fromJson lee el detalle con aportes y fecha nula', () {
    final m = MetaAhorro.fromJson({
      'id': 'x',
      'nombre': 'Viaje',
      'monto_objetivo': 500000,
      'fecha_limite': null,
      'ahorrado': 100000,
      'falta': 400000,
      'porcentaje': 20,
      'cumplida': false,
      'aportes': [
        {'id': 'a1', 'monto': 100000, 'fecha': '2026-10-01'},
      ],
    });
    expect(m.fechaLimite, isNull);
    expect(m.aportes.single.monto, 100000);
    final sinAportes = MetaAhorro.fromJson({
      'id': 'y',
      'nombre': 'Auto',
      'monto_objetivo': 1,
      'fecha_limite': '2026-12-01',
      'ahorrado': 0,
      'falta': 1,
      'porcentaje': 0,
      'cumplida': false,
    });
    expect(sinAportes.aportes, isEmpty);
  });
}
