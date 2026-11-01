import 'package:app_financiera/datos/repositorio_inversion.dart';
import 'package:app_financiera/dominio/modelos.dart';
import 'package:app_financiera/estado/inversion_controlador.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';

const _entidad = EntidadInversion(id: 'banco-socio', nombre: 'Banco socio (simulado)');
const _deposito = InstrumentoInversion(
  id: 'deposito-a-plazo',
  nombre: 'Depósito a plazo',
  tipo: 'Depósito a plazo',
  riesgo: 'bajo',
  plazo: 'De 30 días a 1 año',
  liquidez: 'Media',
  descripcion: 'Prestas tu dinero al banco por un plazo fijo.',
  entidad: _entidad,
  recomendado: true,
);

class _RepoFalso implements RepositorioInversion {
  ErrorApi? fallo;
  final List<(String, int?)> derivaciones = [];

  @override
  Future<OpcionesInversion> opciones() async {
    if (fallo != null) throw fallo!;
    return const OpcionesInversion(
        perfilRiesgo: 'conservador', opciones: [_deposito], aviso: 'Información educativa.');
  }

  @override
  Future<DerivacionInversion> derivar(String instrumentoId, int? monto) async {
    if (fallo != null) throw fallo!;
    derivaciones.add((instrumentoId, monto));
    return DerivacionInversion(
      referencia: 'ref-1',
      instrumentoNombre: _deposito.nombre,
      entidadNombre: _entidad.nombre,
      url: 'https://banco-socio.simulado.invalid/inversiones',
      monto: monto,
      simulada: true,
      mensaje: 'Redirección simulada.',
    );
  }
}

void main() {
  test('cargar trae las opciones y el perfil', () async {
    final c = InversionControlador(_RepoFalso());
    await c.cargar();
    expect(c.opciones!.perfilRiesgo, 'conservador');
    expect(c.opciones!.opciones.single.recomendado, isTrue);
    expect(c.error, isNull);
    expect(c.cargando, isFalse);
  });

  test('derivar guarda el resultado y envía el monto', () async {
    final repo = _RepoFalso();
    final c = InversionControlador(repo);
    expect(await c.derivar(_deposito, monto: 250000), isTrue);
    expect(c.ultima!.simulada, isTrue);
    expect(c.ultima!.monto, 250000);
    expect(repo.derivaciones.single, ('deposito-a-plazo', 250000));
  });

  test('el monto es opcional', () async {
    final repo = _RepoFalso();
    final c = InversionControlador(repo);
    expect(await c.derivar(_deposito), isTrue);
    expect(repo.derivaciones.single.$2, isNull);
  });

  test('un monto de cero no llama al servidor', () async {
    final repo = _RepoFalso();
    final c = InversionControlador(repo);
    expect(await c.derivar(_deposito, monto: 0), isFalse);
    expect(c.error, isNotNull);
    expect(repo.derivaciones, isEmpty);
  });

  test('un error del servidor se muestra y no deja resultado', () async {
    final repo = _RepoFalso()..fallo = const ErrorApi(404, 'Ese instrumento no existe');
    final c = InversionControlador(repo);
    expect(await c.derivar(_deposito), isFalse);
    expect(c.error, 'Ese instrumento no existe');
    expect(c.ultima, isNull);
    expect(c.ocupado, isFalse);
  });

  test('los modelos leen el JSON del servidor', () {
    final o = OpcionesInversion.fromJson({
      'perfil_riesgo': null,
      'aviso': 'x',
      'opciones': [
        {
          'id': 'a',
          'nombre': 'A',
          'tipo': 'T',
          'riesgo': 'alto',
          'plazo': 'p',
          'liquidez': 'l',
          'descripcion': 'd',
          'entidad': {'id': 'e', 'nombre': 'E'},
          'recomendado': false,
        }
      ],
    });
    expect(o.perfilRiesgo, isNull);
    expect(o.opciones.single.entidad.nombre, 'E');
    final d = DerivacionInversion.fromJson({
      'referencia': 'r',
      'instrumento_id': 'a',
      'instrumento_nombre': 'A',
      'entidad': {'id': 'e', 'nombre': 'E'},
      'url': 'https://x.invalid',
      'monto': null,
      'simulada': true,
      'creada_en': '2026-11-01T12:00:00Z',
      'mensaje': 'm',
    });
    expect(d.monto, isNull);
    expect(d.entidadNombre, 'E');
  });
}
