import '../dominio/modelos.dart';
import 'cliente_api.dart';
import '../nucleo/errores.dart';

/// Conexión bancaria (solo lectura) a través de Fintoc. La app nunca ve las
/// credenciales del banco: el servidor guarda cifrado el enlace y lee cuentas y
/// movimientos.
abstract class RepositorioBanco {
  /// Devuelve las cuentas, o null si todavía no hay un banco conectado.
  Future<List<CuentaBancaria>?> cuentas();
  Future<List<CuentaBancaria>> conectar(String linkToken);
  Future<void> desconectar();
  Future<List<MovimientoBanco>> movimientos(String cuentaId);
  Future<ResultadoImportacion> importar(String cuentaId);
}

class RepositorioBancoApi implements RepositorioBanco {
  RepositorioBancoApi(this._api);

  final ClienteApi _api;

  List<CuentaBancaria> _cuentas(dynamic datos) => (datos as List<dynamic>)
      .map((e) => CuentaBancaria.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  Future<List<CuentaBancaria>?> cuentas() async {
    try {
      return _cuentas(await _api.get('/bancos/cuentas'));
    } on ErrorApi catch (e) {
      if (e.estado == 409) return null; // sin banco conectado
      rethrow;
    }
  }

  @override
  Future<List<CuentaBancaria>> conectar(String linkToken) async =>
      _cuentas(await _api.post('/bancos/enlace', cuerpo: {'link_token': linkToken}));

  @override
  Future<void> desconectar() async {
    await _api.delete('/bancos/enlace');
  }

  @override
  Future<List<MovimientoBanco>> movimientos(String cuentaId) async {
    final l = await _api.get(
        '/bancos/cuentas/${Uri.encodeComponent(cuentaId)}/movimientos') as List<dynamic>;
    return l
        .map((e) => MovimientoBanco.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ResultadoImportacion> importar(String cuentaId) async {
    final d = await _api.post(
            '/bancos/cuentas/${Uri.encodeComponent(cuentaId)}/importar')
        as Map<String, dynamic>;
    return ResultadoImportacion.fromJson(d);
  }
}
