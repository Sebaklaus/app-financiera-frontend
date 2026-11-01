import '../dominio/modelos.dart';
import 'cliente_api.dart';

/// Datos para los gráficos del panel.
abstract class RepositorioDashboard {
  Future<List<MesTendencia>> tendencia({int meses = 6});
}

class RepositorioDashboardApi implements RepositorioDashboard {
  RepositorioDashboardApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<MesTendencia>> tendencia({int meses = 6}) async {
    final l = await _api.get('/tendencia?meses=$meses') as List<dynamic>;
    return l.map((e) => MesTendencia.fromJson(e as Map<String, dynamic>)).toList();
  }
}
