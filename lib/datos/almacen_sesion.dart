import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dónde se guarda el token de renovación. Es una interfaz para que el resto de
/// la app no dependa de una tecnología concreta (principio de inversión de
/// dependencias) y para poder probar sin almacenamiento real.
abstract class AlmacenSesion {
  Future<String?> leerRefresco();
  Future<void> guardarRefresco(String token);
  Future<void> borrar();
}

/// Almacenamiento seguro del sistema (Keystore en Android, Keychain en iOS).
class AlmacenSesionSeguro implements AlmacenSesion {
  AlmacenSesionSeguro([FlutterSecureStorage? almacen])
      : _almacen = almacen ?? const FlutterSecureStorage();

  static const _clave = 'refresh_token';
  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leerRefresco() async {
    try {
      return await _almacen.read(key: _clave);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> guardarRefresco(String token) =>
      _almacen.write(key: _clave, value: token);

  @override
  Future<void> borrar() => _almacen.delete(key: _clave);
}

/// Almacén en memoria, usado en las pruebas.
class AlmacenSesionMemoria implements AlmacenSesion {
  String? _token;

  @override
  Future<String?> leerRefresco() async => _token;

  @override
  Future<void> guardarRefresco(String token) async => _token = token;

  @override
  Future<void> borrar() async => _token = null;
}
