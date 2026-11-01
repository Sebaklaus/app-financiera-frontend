import 'package:flutter/foundation.dart';

import '../datos/repositorio_dashboard.dart';
import '../dominio/modelos.dart';
import '../nucleo/errores.dart';

/// Estado de los gráficos del panel: ingresos y gastos de los últimos meses.
class DashboardControlador extends ChangeNotifier {
  DashboardControlador(this._repo);

  final RepositorioDashboard _repo;

  bool cargando = false;
  String? error;
  List<MesTendencia> meses = const [];

  /// El mes más reciente (el actual), o null si todavía no hay datos.
  MesTendencia? get actual => meses.isEmpty ? null : meses.last;

  /// Hay algo que graficar: al menos un mes con ingresos o gastos.
  bool get hayDatos => meses.any((m) => m.ingresos > 0 || m.gastos > 0);

  /// El valor más alto de todas las barras; sirve para dar escala al gráfico.
  int get maximo {
    var tope = 0;
    for (final m in meses) {
      if (m.ingresos > tope) tope = m.ingresos;
      if (m.gastos > tope) tope = m.gastos;
    }
    return tope;
  }

  /// Gastos del mes actual por categoría, solo las que tienen gasto, de mayor a menor.
  List<MapEntry<Categoria, int>> get gastosDelMes {
    final m = actual;
    if (m == null) return const [];
    final lista = m.gastosPorCategoria.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return lista;
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      meses = await _repo.tendencia();
    } on ErrorApi catch (e) {
      error = e.mensaje;
    }
    cargando = false;
    notifyListeners();
  }
}
