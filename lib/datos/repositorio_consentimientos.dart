import '../dominio/modelos.dart';
import 'cliente_api.dart';

abstract class RepositorioConsentimientos {
  Future<EstadoConsentimientos> obtener();
  Future<String?> perfilDeRiesgo();
  Future<void> guardar({
    required bool terminos,
    required bool datosFinancieros,
    required bool comunicaciones,
    required String perfil,
  });
}

class RepositorioConsentimientosApi implements RepositorioConsentimientos {
  RepositorioConsentimientosApi(this._api);

  final ClienteApi _api;

  @override
  Future<EstadoConsentimientos> obtener() async {
    final d = await _api.get('/yo/consentimientos') as Map<String, dynamic>;
    return EstadoConsentimientos.fromJson(d);
  }

  @override
  Future<String?> perfilDeRiesgo() async {
    final d = await _api.get('/yo/perfil-riesgo') as Map<String, dynamic>;
    return d['perfil'] as String?;
  }

  @override
  Future<void> guardar({
    required bool terminos,
    required bool datosFinancieros,
    required bool comunicaciones,
    required String perfil,
  }) async {
    await _api.put('/yo/consentimientos', cuerpo: {
      'terminos_y_privacidad': terminos,
      'datos_financieros': datosFinancieros,
      'comunicaciones': comunicaciones,
    });
    await _api.put('/yo/perfil-riesgo', cuerpo: {'perfil': perfil});
  }
}
