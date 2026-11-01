import 'package:flutter/foundation.dart';

import '../datos/repositorio_inversion.dart';
import '../dominio/modelos.dart';
import '../nucleo/errores.dart';

/// Estado de la pantalla de inversión: opciones según el perfil y la derivación simulada.
class InversionControlador extends ChangeNotifier {
  InversionControlador(this._repo);

  final RepositorioInversion _repo;

  bool cargando = false;
  bool ocupado = false;
  String? error;
  OpcionesInversion? opciones;

  /// Última derivación hecha; sirve para mostrar el resultado.
  DerivacionInversion? ultima;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      opciones = await _repo.opciones();
    } on ErrorApi catch (e) {
      error = e.mensaje;
    }
    cargando = false;
    notifyListeners();
  }

  /// [monto] es opcional: solo orienta, no se mueve dinero.
  Future<bool> derivar(InstrumentoInversion instrumento, {int? monto}) async {
    if (monto != null && monto <= 0) {
      error = 'El monto debe ser mayor a cero.';
      notifyListeners();
      return false;
    }
    ocupado = true;
    error = null;
    ultima = null;
    notifyListeners();
    try {
      ultima = await _repo.derivar(instrumento.id, monto);
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
