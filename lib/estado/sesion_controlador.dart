import 'package:flutter/foundation.dart';

import '../datos/repositorio_auth.dart';
import '../nucleo/errores.dart';

enum EstadoSesion { cargando, sinSesion, activa }

/// Estado de la sesión para las pantallas. No conoce HTTP: usa [RepositorioAuth].
class SesionControlador extends ChangeNotifier {
  SesionControlador(this._repo);

  final RepositorioAuth _repo;

  EstadoSesion _estado = EstadoSesion.cargando;
  bool _ocupado = false;
  String? _error;
  String? _email;

  EstadoSesion get estado => _estado;
  bool get ocupado => _ocupado;
  String? get error => _error;
  String? get email => _email;

  /// Al abrir la app: intenta recuperar la sesión guardada.
  Future<void> iniciar() async {
    final activa = await _repo.restaurar();
    _estado = activa ? EstadoSesion.activa : EstadoSesion.sinSesion;
    notifyListeners();
  }

  Future<bool> iniciarSesion(String email, String contrasena) =>
      _autenticar(email, () => _repo.iniciarSesion(email.trim(), contrasena));

  Future<bool> registrar(String email, String contrasena) =>
      _autenticar(email, () => _repo.registrar(email.trim(), contrasena));

  Future<bool> _autenticar(String email, Future<void> Function() accion) async {
    if (!_correoValido(email)) {
      _error = 'Escribe un correo válido.';
      notifyListeners();
      return false;
    }
    _ocupado = true;
    _error = null;
    notifyListeners();
    try {
      await accion();
      _email = email.trim();
      _estado = EstadoSesion.activa;
      return true;
    } on ErrorApi catch (e) {
      _error = e.estado == 401 ? 'Correo o contraseña incorrectos.' : e.mensaje;
      return false;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  /// Devuelve un mensaje de error, o null si salió bien. La respuesta del servidor
  /// es la misma exista o no la cuenta, así que aquí tampoco se distingue.
  Future<String?> solicitarRecuperacion(String email) async {
    if (!_correoValido(email)) return 'Escribe un correo válido.';
    try {
      await _repo.solicitarRecuperacion(email.trim());
      return null;
    } on ErrorApi catch (e) {
      return e.mensaje;
    }
  }

  Future<String?> restablecerContrasena(String token, String nueva) async {
    if (token.trim().isEmpty) return 'Pega el código que recibiste.';
    try {
      await _repo.restablecerContrasena(token.trim(), nueva);
      return null;
    } on ErrorApi catch (e) {
      return e.mensaje;
    }
  }

  Future<void> cerrarSesion() async {
    await _repo.cerrarSesion();
    _estado = EstadoSesion.sinSesion;
    _email = null;
    _error = null;
    notifyListeners();
  }

  /// La API ya no acepta la sesión guardada: hay que volver a entrar.
  void sesionExpirada() {
    if (_estado != EstadoSesion.activa) return;
    _estado = EstadoSesion.sinSesion;
    _error = 'Tu sesión expiró. Vuelve a iniciar sesión.';
    notifyListeners();
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  bool _correoValido(String v) {
    final t = v.trim();
    return t.contains('@') && t.contains('.') && !t.contains(' ');
  }
}
