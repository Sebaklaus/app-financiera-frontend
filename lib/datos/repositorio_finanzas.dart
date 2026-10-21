import '../dominio/modelos.dart';
import 'cliente_api.dart';

/// Operaciones de dinero que usa la app. Los controladores dependen de esta
/// interfaz, no de HTTP.
abstract class RepositorioFinanzas {
  Future<IngresoRegistrado> registrarIngreso(int monto, String descripcion);
  Future<void> registrarGasto(int monto, Categoria categoria, String descripcion);
  Future<List<Confirmacion>> confirmacionesPendientes();
  Future<void> decidir(String confirmacionId, {required bool confirmar});
  Future<Resumen> resumen({String? mes});
  Future<List<Movimiento>> movimientos();
  Future<void> eliminarMovimiento(String id);
}

class RepositorioFinanzasApi implements RepositorioFinanzas {
  RepositorioFinanzasApi(this._api);

  final ClienteApi _api;

  @override
  Future<IngresoRegistrado> registrarIngreso(
      int monto, String descripcion) async {
    final d = await _api.post('/ingresos',
        cuerpo: {'monto': monto, 'descripcion': descripcion}) as Map<String, dynamic>;
    return IngresoRegistrado.fromJson(d);
  }

  @override
  Future<void> registrarGasto(
      int monto, Categoria categoria, String descripcion) async {
    await _api.post('/gastos', cuerpo: {
      'monto': monto,
      'categoria': categoria.clave,
      'descripcion': descripcion,
    });
  }

  @override
  Future<List<Confirmacion>> confirmacionesPendientes() async {
    final l = await _api.get('/confirmaciones/pendientes') as List<dynamic>;
    return l
        .map((e) => Confirmacion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> decidir(String confirmacionId, {required bool confirmar}) async {
    await _api.post('/confirmaciones/$confirmacionId/decision',
        cuerpo: {'decision': confirmar ? 'confirmar' : 'rechazar'});
  }

  @override
  Future<Resumen> resumen({String? mes}) async {
    final ruta = mes == null ? '/resumen' : '/resumen?mes=$mes';
    final d = await _api.get(ruta) as Map<String, dynamic>;
    return Resumen.fromJson(d);
  }

  @override
  Future<List<Movimiento>> movimientos() async {
    final l = await _api.get('/movimientos') as List<dynamic>;
    return l
        .map((e) => Movimiento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> eliminarMovimiento(String id) async {
    await _api.delete('/movimientos/$id');
  }
}
