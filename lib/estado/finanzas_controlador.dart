import 'package:flutter/foundation.dart';

import '../datos/repositorio_finanzas.dart';
import '../dominio/modelos.dart';
import '../nucleo/errores.dart';

/// Estado de las finanzas de la persona: resumen, movimientos y confirmaciones.
/// Después de cada cambio vuelve a pedir los datos al servidor, de modo que la
/// pantalla siempre muestra lo que realmente quedó guardado.
class FinanzasControlador extends ChangeNotifier {
  FinanzasControlador(this._repo);

  final RepositorioFinanzas _repo;

  Resumen? resumen;
  List<Movimiento> movimientos = const [];
  List<Confirmacion> pendientes = const [];
  bool cargando = false;
  bool ocupado = false;
  String? error;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    await _recargar();
    cargando = false;
    notifyListeners();
  }

  Future<void> _recargar() async {
    try {
      final (res, movs, pend) = await (
        _repo.resumen(),
        _repo.movimientos(),
        _repo.confirmacionesPendientes(),
      ).wait;
      resumen = res;
      movimientos = movs;
      pendientes = pend;
    } on ErrorApi catch (e) {
      error = e.mensaje;
    }
  }

  Future<bool> _accion(Future<void> Function() accion) async {
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      await accion();
    } on ErrorApi catch (e) {
      error = e.mensaje;
      ocupado = false;
      notifyListeners();
      return false;
    }
    await _recargar();
    ocupado = false;
    notifyListeners();
    return true;
  }

  Future<IngresoRegistrado?> registrarIngreso(int monto, String descripcion) async {
    if (monto <= 0) {
      error = 'El monto debe ser mayor a cero.';
      notifyListeners();
      return null;
    }
    IngresoRegistrado? resultado;
    final ok = await _accion(() async {
      resultado = await _repo.registrarIngreso(monto, descripcion);
    });
    return ok ? resultado : null;
  }

  Future<bool> registrarGasto(int monto, Categoria categoria, String descripcion) {
    if (monto <= 0) {
      error = 'El monto debe ser mayor a cero.';
      notifyListeners();
      return Future.value(false);
    }
    return _accion(() => _repo.registrarGasto(monto, categoria, descripcion));
  }

  Future<bool> decidir(Confirmacion c, {required bool confirmar}) =>
      _accion(() => _repo.decidir(c.id, confirmar: confirmar));

  Future<bool> eliminarMovimiento(Movimiento m) =>
      _accion(() => _repo.eliminarMovimiento(m.id));
}
