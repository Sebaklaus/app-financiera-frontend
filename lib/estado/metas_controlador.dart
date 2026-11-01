import 'package:flutter/foundation.dart';

import '../datos/repositorio_metas.dart';
import '../dominio/modelos.dart';
import '../nucleo/errores.dart';

/// Estado de las metas de ahorro: lista, creación, aportes y borrado.
class MetasControlador extends ChangeNotifier {
  MetasControlador(this._repo);

  final RepositorioMetas _repo;

  bool cargando = false;
  bool ocupado = false;
  String? error;
  List<MetaAhorro> metas = const [];

  /// Meta abierta en el detalle (con su historial de aportes).
  MetaAhorro? abierta;

  int get totalAhorrado => metas.fold(0, (s, m) => s + m.ahorrado);
  int get cumplidas => metas.where((m) => m.cumplida).length;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      metas = await _repo.listar();
    } on ErrorApi catch (e) {
      error = e.mensaje;
    }
    cargando = false;
    notifyListeners();
  }

  /// Devuelve null si el nombre o el monto no sirven, sin llamar al servidor.
  static String? validarMeta(String nombre, int? monto) {
    if (nombre.trim().isEmpty) return 'Ponle un nombre a tu meta.';
    if (nombre.trim().length > 80) return 'El nombre puede tener hasta 80 letras.';
    if (monto == null || monto <= 0) return 'Escribe un monto mayor a cero.';
    return null;
  }

  Future<bool> crear(String nombre, int? monto, {String? fechaLimite}) async {
    final problema = validarMeta(nombre, monto);
    if (problema != null) {
      error = problema;
      notifyListeners();
      return false;
    }
    return _accion(() async {
      await _repo.crear(nombre.trim(), monto!, fechaLimite);
      metas = await _repo.listar();
    });
  }

  Future<bool> abrir(String metaId) => _accion(() async {
        abierta = await _repo.detalle(metaId);
      });

  void cerrar() {
    abierta = null;
    notifyListeners();
  }

  Future<bool> aportar(String metaId, int? monto, {String? fecha}) async {
    if (monto == null || monto <= 0) {
      error = 'Escribe un monto mayor a cero.';
      notifyListeners();
      return false;
    }
    return _accion(() async {
      abierta = await _repo.aportar(metaId, monto, fecha);
      metas = await _repo.listar();
    });
  }

  Future<bool> eliminar(String metaId) => _accion(() async {
        await _repo.eliminar(metaId);
        abierta = null;
        metas = await _repo.listar();
      });

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
