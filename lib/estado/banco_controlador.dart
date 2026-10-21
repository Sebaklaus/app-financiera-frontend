import 'package:flutter/foundation.dart';

import '../datos/repositorio_banco.dart';
import '../dominio/modelos.dart';
import '../nucleo/errores.dart';

/// Estado de la conexión bancaria. Después de importar abonos avisa a las
/// finanzas para que recarguen el resumen y las confirmaciones.
class BancoControlador extends ChangeNotifier {
  BancoControlador(this._repo, {required this.alImportar});

  final RepositorioBanco _repo;
  final Future<void> Function() alImportar;

  bool cargando = false;
  bool ocupado = false;
  String? error;
  String? aviso;

  /// null = todavía no hay banco conectado.
  List<CuentaBancaria>? cuentas;
  CuentaBancaria? seleccionada;
  List<MovimientoBanco> movimientos = const [];

  bool get conectado => cuentas != null;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      cuentas = await _repo.cuentas();
    } on ErrorApi catch (e) {
      error = e.mensaje;
    }
    cargando = false;
    notifyListeners();
  }

  Future<bool> conectar(String linkToken) async {
    final token = linkToken.trim();
    if (token.isEmpty) {
      error = 'Pega el enlace (link_token) de tu banco de prueba.';
      notifyListeners();
      return false;
    }
    return _accion(() async {
      cuentas = await _repo.conectar(token);
      aviso = 'Banco conectado: el enlace quedó guardado cifrado en el servidor.';
    });
  }

  Future<bool> desconectar() => _accion(() async {
        await _repo.desconectar();
        cuentas = null;
        seleccionada = null;
        movimientos = const [];
        aviso = 'Banco desconectado: se borró el enlace.';
      });

  Future<bool> verMovimientos(CuentaBancaria cuenta) => _accion(() async {
        movimientos = await _repo.movimientos(cuenta.id);
        seleccionada = cuenta;
      });

  Future<bool> importar() {
    final cuenta = seleccionada;
    if (cuenta == null) return Future.value(false);
    return _accion(() async {
      final r = await _repo.importar(cuenta.id);
      aviso = 'Importados: ${r.importados} · ya importados: ${r.yaImportados} '
          '· cargos sin importar: ${r.cargosOmitidos}. '
          'Revisa la pestaña Confirmar.';
      await alImportar();
    });
  }

  Future<bool> _accion(Future<void> Function() accion) async {
    ocupado = true;
    error = null;
    aviso = null;
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
