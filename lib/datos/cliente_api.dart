import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nucleo/errores.dart';
import 'almacen_sesion.dart';

/// Único punto que habla HTTP con el backend. Ninguna pantalla llama a la red
/// directamente. Se encarga de:
///  - enviar el token de acceso (solo en memoria) en cada solicitud;
///  - renovar la sesión una vez si el servidor responde 401;
///  - traducir los errores del servidor a mensajes en español.
class ClienteApi {
  ClienteApi({
    required String urlBase,
    required AlmacenSesion almacen,
    http.Client? cliente,
  })  : _base = urlBase.endsWith('/')
            ? urlBase.substring(0, urlBase.length - 1)
            : urlBase,
        _almacen = almacen,
        _http = cliente ?? http.Client();

  final String _base;
  final AlmacenSesion _almacen;
  final http.Client _http;

  String? _acceso;
  String? _refresco;
  Future<bool>? _renovando;

  /// Se llama cuando la sesión ya no se puede renovar (hay que volver a entrar).
  void Function()? alExpirarSesion;

  String? get refresco => _refresco;

  Future<void> establecerSesion(String acceso, String refresco) async {
    _acceso = acceso;
    _refresco = refresco;
    await _almacen.guardarRefresco(refresco);
  }

  Future<void> limpiarSesion() async {
    _acceso = null;
    _refresco = null;
    await _almacen.borrar();
  }

  /// Intenta recuperar la sesión guardada. Devuelve true si quedó activa.
  Future<bool> restaurarSesion() async {
    _refresco = await _almacen.leerRefresco();
    if (_refresco == null) return false;
    return _renovar();
  }

  Future<dynamic> get(String ruta) => _enviar('GET', ruta);

  Future<dynamic> post(String ruta, {Object? cuerpo, bool auth = true}) =>
      _enviar('POST', ruta, cuerpo: cuerpo, auth: auth);

  Future<dynamic> put(String ruta, {Object? cuerpo}) =>
      _enviar('PUT', ruta, cuerpo: cuerpo);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  // Si varias solicitudes fallan a la vez con 401, solo se renueva una vez.
  Future<bool> _renovar() =>
      _renovando ??= _hacerRenovacion().whenComplete(() => _renovando = null);

  Future<bool> _hacerRenovacion() async {
    final actual = _refresco;
    if (actual == null) return false;
    try {
      final d = await _enviar(
        'POST',
        '/refrescar',
        cuerpo: {'refresh_token': actual},
        auth: false,
        reintento: false,
      ) as Map<String, dynamic>;
      await establecerSesion(
        d['access_token'] as String,
        d['refresh_token'] as String,
      );
      return true;
    } on ErrorApi catch (e) {
      // Sin conexión no se pierde la sesión; solo si el servidor la rechaza.
      if (!e.esSinConexion) {
        await limpiarSesion();
        alExpirarSesion?.call();
      }
      return false;
    }
  }

  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Object? cuerpo,
    bool auth = true,
    bool reintento = true,
  }) async {
    final peticion = http.Request(metodo, Uri.parse('$_base$ruta'))
      ..headers['Accept'] = 'application/json';
    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json';
      peticion.body = jsonEncode(cuerpo);
    }
    if (auth && _acceso != null) {
      peticion.headers['Authorization'] = 'Bearer $_acceso';
    }

    final http.Response r;
    try {
      final flujo = await _http.send(peticion).timeout(
            const Duration(seconds: 20),
          );
      r = await http.Response.fromStream(flujo);
    } on TimeoutException {
      throw const ErrorApi(null, 'El servidor tardó demasiado en responder.');
    } catch (_) {
      throw const ErrorApi(
        null,
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (r.statusCode == 401 && auth && reintento && _refresco != null) {
      if (await _renovar()) {
        return _enviar(metodo, ruta,
            cuerpo: cuerpo, auth: auth, reintento: false);
      }
    }

    dynamic datos;
    if (r.bodyBytes.isNotEmpty) {
      try {
        datos = jsonDecode(utf8.decode(r.bodyBytes));
      } catch (_) {
        datos = null;
      }
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ErrorApi(r.statusCode, _mensaje(datos, r.statusCode));
    }
    return datos;
  }

  String _mensaje(dynamic datos, int estado) {
    if (datos is Map && datos['detail'] is String) {
      return datos['detail'] as String;
    }
    if (datos is Map && datos['detail'] is List) {
      final msgs = (datos['detail'] as List)
          .whereType<Map>()
          .map((e) => e['msg']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toList();
      if (msgs.isNotEmpty) return msgs.join('; ');
    }
    if (estado == 401) return 'Credenciales inválidas o sesión vencida.';
    if (estado == 429) {
      return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
    }
    if (estado >= 500) return 'El servidor tuvo un problema. Inténtalo más tarde.';
    return 'Error $estado.';
  }
}
