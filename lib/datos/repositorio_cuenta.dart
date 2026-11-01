import '../dominio/modelos.dart';
import 'cliente_api.dart';

/// Derechos sobre los propios datos: ver, cambiar la contraseña y eliminar la cuenta.
abstract class RepositorioCuenta {
  Future<DatosCuenta> datos();
  Future<List<EventoActividad>> actividad();
  Future<void> cambiarContrasena(String actual, String nueva);
  Future<void> eliminarCuenta(String contrasena);
}

class RepositorioCuentaApi implements RepositorioCuenta {
  RepositorioCuentaApi(this._api);

  final ClienteApi _api;

  @override
  Future<DatosCuenta> datos() async =>
      DatosCuenta.fromJson(await _api.get('/yo/datos') as Map<String, dynamic>);

  @override
  Future<List<EventoActividad>> actividad() async =>
      ((await _api.get('/yo/actividad?limite=20')) as List<dynamic>)
          .map((e) => EventoActividad.fromJson(e as Map<String, dynamic>))
          .toList();

  @override
  Future<void> cambiarContrasena(String actual, String nueva) async {
    await _api.post('/yo/contrasena',
        cuerpo: {'contrasena_actual': actual, 'contrasena_nueva': nueva});
  }

  @override
  Future<void> eliminarCuenta(String contrasena) async {
    await _api.post('/yo/eliminar', cuerpo: {'contrasena': contrasena});
  }
}
