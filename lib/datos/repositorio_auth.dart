import '../nucleo/errores.dart';
import 'cliente_api.dart';

/// Contrato de autenticación que usa la app. El controlador de sesión depende de
/// esta interfaz, no de HTTP.
abstract class RepositorioAuth {
  Future<bool> restaurar();
  Future<void> iniciarSesion(String email, String contrasena);
  Future<void> registrar(String email, String contrasena);
  Future<void> cerrarSesion();
}

class RepositorioAuthApi implements RepositorioAuth {
  RepositorioAuthApi(this._api);

  final ClienteApi _api;

  @override
  Future<bool> restaurar() => _api.restaurarSesion();

  @override
  Future<void> iniciarSesion(String email, String contrasena) async {
    final d = await _api.post(
      '/login',
      cuerpo: {'email': email, 'contrasena': contrasena},
      auth: false,
    ) as Map<String, dynamic>;
    await _api.establecerSesion(
      d['access_token'] as String,
      d['refresh_token'] as String,
    );
  }

  @override
  Future<void> registrar(String email, String contrasena) async {
    await _api.post(
      '/registro',
      cuerpo: {'email': email, 'contrasena': contrasena},
      auth: false,
    );
    await iniciarSesion(email, contrasena);
  }

  @override
  Future<void> cerrarSesion() async {
    final refresco = _api.refresco;
    if (refresco != null) {
      try {
        await _api.post('/logout',
            cuerpo: {'refresh_token': refresco}, auth: false);
      } on ErrorApi {
        // Aunque el servidor no responda, la sesión se cierra en este equipo.
      }
    }
    await _api.limpiarSesion();
  }
}
