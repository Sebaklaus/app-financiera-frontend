import '../dominio/modelos.dart';
import 'cliente_api.dart';

/// Metas de ahorro. La app solo anota lo que la persona dice haber apartado.
abstract class RepositorioMetas {
  Future<List<MetaAhorro>> listar();
  Future<MetaAhorro> crear(String nombre, int montoObjetivo, String? fechaLimite);
  Future<MetaAhorro> detalle(String metaId);
  Future<MetaAhorro> aportar(String metaId, int monto, String? fecha);
  Future<void> eliminar(String metaId);
}

class RepositorioMetasApi implements RepositorioMetas {
  RepositorioMetasApi(this._api);

  final ClienteApi _api;

  String _ruta(String id) => '/metas/${Uri.encodeComponent(id)}';

  MetaAhorro _meta(dynamic d) => MetaAhorro.fromJson(d as Map<String, dynamic>);

  @override
  Future<List<MetaAhorro>> listar() async =>
      ((await _api.get('/metas')) as List<dynamic>).map(_meta).toList();

  @override
  Future<MetaAhorro> crear(String nombre, int montoObjetivo, String? fechaLimite) async =>
      _meta(await _api.post('/metas', cuerpo: {
        'nombre': nombre,
        'monto_objetivo': montoObjetivo,
        if (fechaLimite != null) 'fecha_limite': fechaLimite,
      }));

  @override
  Future<MetaAhorro> detalle(String metaId) async => _meta(await _api.get(_ruta(metaId)));

  @override
  Future<MetaAhorro> aportar(String metaId, int monto, String? fecha) async =>
      _meta(await _api.post('${_ruta(metaId)}/aportes', cuerpo: {
        'monto': monto,
        if (fecha != null) 'fecha': fecha,
      }));

  @override
  Future<void> eliminar(String metaId) async {
    await _api.delete(_ruta(metaId));
  }
}
