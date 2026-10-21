import 'package:flutter/foundation.dart';

import '../datos/repositorio_consentimientos.dart';
import '../nucleo/errores.dart';

/// Pantalla de consentimientos (Ley 21.719): cada uno se otorga por separado y
/// los obligatorios deben estar aceptados antes de usar la app.
class ConsentimientosControlador extends ChangeNotifier {
  ConsentimientosControlador(this._repo);

  final RepositorioConsentimientos _repo;

  bool cargando = true;
  bool completo = false;
  bool ocupado = false;
  String? error;

  bool terminos = false;
  bool datosFinancieros = false;
  bool comunicaciones = false;
  String perfil = 'moderado';

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final estado = await _repo.obtener();
      terminos = estado.otorgados['terminos_y_privacidad'] ?? false;
      datosFinancieros = estado.otorgados['datos_financieros'] ?? false;
      comunicaciones = estado.otorgados['comunicaciones'] ?? false;
      completo = estado.completo;
      perfil = await _repo.perfilDeRiesgo() ?? perfil;
    } on ErrorApi catch (e) {
      error = e.mensaje;
      completo = false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void cambiar({bool? terminos, bool? datosFinancieros, bool? comunicaciones, String? perfil}) {
    this.terminos = terminos ?? this.terminos;
    this.datosFinancieros = datosFinancieros ?? this.datosFinancieros;
    this.comunicaciones = comunicaciones ?? this.comunicaciones;
    this.perfil = perfil ?? this.perfil;
    error = null;
    notifyListeners();
  }

  Future<bool> guardar() async {
    if (!terminos || !datosFinancieros) {
      error = 'Para continuar debes aceptar los términos y el uso de tus datos financieros.';
      notifyListeners();
      return false;
    }
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      await _repo.guardar(
        terminos: terminos,
        datosFinancieros: datosFinancieros,
        comunicaciones: comunicaciones,
        perfil: perfil,
      );
    } on ErrorApi catch (e) {
      error = e.mensaje;
      ocupado = false;
      notifyListeners();
      return false;
    }
    ocupado = false;
    await cargar();
    return completo;
  }
}
