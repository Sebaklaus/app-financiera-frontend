import 'package:flutter/foundation.dart';

import '../datos/repositorio_cuenta.dart';
import '../dominio/modelos.dart';
import '../nucleo/errores.dart';

/// Estado de "Mi cuenta": datos guardados, actividad, cambio de contraseña y eliminación.
class CuentaControlador extends ChangeNotifier {
  CuentaControlador(this._repo);

  final RepositorioCuenta _repo;

  bool cargando = false;
  bool ocupado = false;
  String? error;
  DatosCuenta? datos;
  List<EventoActividad> actividad = const [];

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final (d, a) = await (_repo.datos(), _repo.actividad()).wait;
      datos = d;
      actividad = a;
    } on ErrorApi catch (e) {
      error = e.mensaje;
    }
    cargando = false;
    notifyListeners();
  }

  /// Texto del problema, o null si el cambio puede enviarse.
  static String? validarCambio(String actual, String nueva, String repetida) {
    if (actual.isEmpty) return 'Escribe tu contraseña actual.';
    if (nueva.isEmpty) return 'Escribe la contraseña nueva.';
    if (nueva == actual) return 'La contraseña nueva debe ser distinta de la actual.';
    if (nueva != repetida) return 'Las contraseñas nuevas no coinciden.';
    return null;
  }

  /// Si sale bien, el servidor cierra todas las sesiones: hay que volver a entrar.
  Future<bool> cambiarContrasena(String actual, String nueva, String repetida) async {
    final problema = validarCambio(actual, nueva, repetida);
    if (problema != null) {
      error = problema;
      notifyListeners();
      return false;
    }
    return _accion(() => _repo.cambiarContrasena(actual, nueva));
  }

  Future<bool> eliminarCuenta(String contrasena) async {
    if (contrasena.isEmpty) {
      error = 'Escribe tu contraseña para confirmar.';
      notifyListeners();
      return false;
    }
    return _accion(() => _repo.eliminarCuenta(contrasena));
  }

  Future<bool> _accion(Future<void> Function() accion) async {
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } on ErrorApi catch (e) {
      error = e.mensaje;
      return false;
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }
}
