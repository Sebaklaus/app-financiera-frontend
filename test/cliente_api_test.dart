import 'dart:convert';

import 'package:app_financiera/datos/almacen_sesion.dart';
import 'package:app_financiera/datos/cliente_api.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int estado, Object cuerpo) => http.Response(
      jsonEncode(cuerpo),
      estado,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('envía el token de acceso en la cabecera Authorization', () async {
    String? cabecera;
    final cliente = MockClient((req) async {
      cabecera = req.headers['Authorization'];
      return _json(200, {'ok': true});
    });
    final api = ClienteApi(
        urlBase: 'http://x', almacen: AlmacenSesionMemoria(), cliente: cliente);
    await api.establecerSesion('acceso-1', 'refresco-1');

    await api.get('/resumen');

    expect(cabecera, 'Bearer acceso-1');
  });

  test('ante un 401 renueva la sesión una vez y reintenta', () async {
    final llamadas = <String>[];
    final cliente = MockClient((req) async {
      llamadas.add('${req.method} ${req.url.path}');
      if (req.url.path == '/refrescar') {
        return _json(200,
            {'access_token': 'acceso-2', 'refresh_token': 'refresco-2'});
      }
      if (req.headers['Authorization'] == 'Bearer acceso-2') {
        return _json(200, {'dato': 1});
      }
      return _json(401, {'detail': 'Token vencido'});
    });
    final almacen = AlmacenSesionMemoria();
    final api =
        ClienteApi(urlBase: 'http://x', almacen: almacen, cliente: cliente);
    await api.establecerSesion('acceso-1', 'refresco-1');

    final r = await api.get('/resumen') as Map<String, dynamic>;

    expect(r['dato'], 1);
    expect(llamadas, ['GET /resumen', 'POST /refrescar', 'GET /resumen']);
    expect(await almacen.leerRefresco(), 'refresco-2');
  });

  test('si la renovación falla, cierra la sesión y avisa', () async {
    final cliente = MockClient((req) async => _json(401, {'detail': 'No'}));
    final almacen = AlmacenSesionMemoria();
    final api =
        ClienteApi(urlBase: 'http://x', almacen: almacen, cliente: cliente);
    var avisos = 0;
    api.alExpirarSesion = () => avisos++;
    await api.establecerSesion('a', 'r');

    await expectLater(api.get('/resumen'), throwsA(isA<ErrorApi>()));

    expect(avisos, 1);
    expect(await almacen.leerRefresco(), isNull);
  });

  test('traduce los errores de validación del servidor', () async {
    final cliente = MockClient((req) async => _json(422, {
          'detail': [
            {'msg': 'Contraseña demasiado corta'},
            {'msg': 'Correo inválido'}
          ]
        }));
    final api = ClienteApi(
        urlBase: 'http://x', almacen: AlmacenSesionMemoria(), cliente: cliente);

    try {
      await api.post('/registro', cuerpo: {}, auth: false);
      fail('debía lanzar ErrorApi');
    } on ErrorApi catch (e) {
      expect(e.estado, 422);
      expect(e.mensaje, 'Contraseña demasiado corta; Correo inválido');
    }
  });

  test('sin conexión lanza un error sin código HTTP', () async {
    final cliente = MockClient((req) async => throw Exception('sin red'));
    final api = ClienteApi(
        urlBase: 'http://x', almacen: AlmacenSesionMemoria(), cliente: cliente);

    try {
      await api.get('/salud/listo');
      fail('debía lanzar ErrorApi');
    } on ErrorApi catch (e) {
      expect(e.esSinConexion, isTrue);
    }
  });
}
