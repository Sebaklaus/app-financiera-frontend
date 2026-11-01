import 'package:app_financiera/datos/repositorio_cuenta.dart';
import 'package:app_financiera/dominio/modelos.dart';
import 'package:app_financiera/estado/cuenta_controlador.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoFalso implements RepositorioCuenta {
  ErrorApi? fallo;
  final List<String> llamadas = [];

  @override
  Future<DatosCuenta> datos() async => DatosCuenta(
        email: 'ana@correo.cl',
        creadoEn: DateTime(2026, 10, 1),
        movimientos: 3,
        confirmaciones: 4,
        consentimientos: 2,
        perfilRiesgo: 'moderado',
      );

  @override
  Future<List<EventoActividad>> actividad() async =>
      [EventoActividad(tipo: 'login_exitoso', fecha: DateTime(2026, 11, 1))];

  @override
  Future<void> cambiarContrasena(String actual, String nueva) async {
    llamadas.add('cambiar');
    if (fallo != null) throw fallo!;
  }

  @override
  Future<void> eliminarCuenta(String contrasena) async {
    llamadas.add('eliminar');
    if (fallo != null) throw fallo!;
  }
}

void main() {
  test('cargar trae los datos y la actividad', () async {
    final c = CuentaControlador(_RepoFalso());
    await c.cargar();
    expect(c.datos!.email, 'ana@correo.cl');
    expect(c.datos!.movimientos, 3);
    expect(c.actividad.single.etiqueta, 'Inicio de sesión');
    expect(c.error, isNull);
  });

  test('validarCambio detecta los errores comunes', () {
    expect(CuentaControlador.validarCambio('', 'Nueva1234', 'Nueva1234'), isNotNull);
    expect(CuentaControlador.validarCambio('Vieja1234', '', ''), isNotNull);
    expect(CuentaControlador.validarCambio('Igual1234', 'Igual1234', 'Igual1234'), isNotNull);
    expect(CuentaControlador.validarCambio('Vieja1234', 'Nueva1234', 'Otra12345'), isNotNull);
    expect(CuentaControlador.validarCambio('Vieja1234', 'Nueva1234', 'Nueva1234'), isNull);
  });

  test('un cambio inválido no llama al servidor', () async {
    final repo = _RepoFalso();
    final c = CuentaControlador(repo);
    expect(await c.cambiarContrasena('Vieja1234', 'Nueva1234', 'No coincide'), isFalse);
    expect(c.error, contains('no coinciden'));
    expect(repo.llamadas, isEmpty);
  });

  test('cambiar la contraseña correctamente devuelve true', () async {
    final repo = _RepoFalso();
    final c = CuentaControlador(repo);
    expect(await c.cambiarContrasena('Vieja1234', 'Nueva1234', 'Nueva1234'), isTrue);
    expect(repo.llamadas, ['cambiar']);
    expect(c.ocupado, isFalse);
  });

  test('una contraseña actual incorrecta muestra el error del servidor', () async {
    final repo = _RepoFalso()..fallo = const ErrorApi(403, 'La contraseña no es correcta');
    final c = CuentaControlador(repo);
    expect(await c.cambiarContrasena('Mala12345', 'Nueva1234', 'Nueva1234'), isFalse);
    expect(c.error, 'La contraseña no es correcta');
  });

  test('eliminar exige la contraseña', () async {
    final repo = _RepoFalso();
    final c = CuentaControlador(repo);
    expect(await c.eliminarCuenta(''), isFalse);
    expect(repo.llamadas, isEmpty);
    expect(await c.eliminarCuenta('Clave1234'), isTrue);
    expect(repo.llamadas, ['eliminar']);
  });

  test('un tipo de evento desconocido se muestra tal cual', () {
    expect(EventoActividad(tipo: 'evento_nuevo', fecha: DateTime(2026)).etiqueta, 'evento_nuevo');
    expect(EventoActividad(tipo: 'derivacion_inversion', fecha: DateTime(2026)).etiqueta,
        contains('simulada'));
  });
}
