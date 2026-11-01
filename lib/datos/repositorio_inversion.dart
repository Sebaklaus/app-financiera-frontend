import '../dominio/modelos.dart';
import 'cliente_api.dart';

/// Opciones de inversión y paso a la entidad socia. La app nunca mueve dinero.
abstract class RepositorioInversion {
  Future<OpcionesInversion> opciones();
  Future<DerivacionInversion> derivar(String instrumentoId, int? monto);
}

class RepositorioInversionApi implements RepositorioInversion {
  RepositorioInversionApi(this._api);

  final ClienteApi _api;

  @override
  Future<OpcionesInversion> opciones() async => OpcionesInversion.fromJson(
      await _api.get('/inversion/opciones') as Map<String, dynamic>);

  @override
  Future<DerivacionInversion> derivar(String instrumentoId, int? monto) async =>
      DerivacionInversion.fromJson(await _api.post('/inversion/derivaciones', cuerpo: {
        'instrumento_id': instrumentoId,
        if (monto != null) 'monto': monto,
      }) as Map<String, dynamic>);
}
