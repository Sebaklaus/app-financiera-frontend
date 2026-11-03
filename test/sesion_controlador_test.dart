import 'package:app_financiera/datos/repositorio_auth.dart';
import 'package:app_financiera/estado/sesion_controlador.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio falso: permite probar el controlador sin red.
class _RepoFalso implements RepositorioAuth {
  _RepoFalso({this.fallo, this.hayGuardada = false});

  final ErrorApi? fallo;
  final bool hayGuardada;
  bool cerro = false;

  @override
  Future<bool> restaurar() async => hayGuardada;

  @override
  Future<void> iniciarSesion(String email, String contrasena) async {
    if (fallo != null) throw fallo!;
  }

  @override
  Future<void> registrar(String email, String contrasena) async {
    if (fallo != null) throw fallo!;
  }

  @override
  Future<void> cerrarSesion() async => cerro = true;

  @override
  Future<void> solicitarRecuperacion(String email) async {
    if (fallo != null) throw fallo!;
  }

  @override
  Future<void> restablecerContrasena(String token, String contrasenaNueva) async {
    if (fallo != null) throw fallo!;
  }
}

void main() {
  test('al abrir sin sesión guardada queda en sinSesion', () async {
    final c = SesionControlador(_RepoFalso());
    expect(c.estado, EstadoSesion.cargando);
    await c.iniciar();
    expect(c.estado, EstadoSesion.sinSesion);
  });

  test('al abrir con sesión guardada queda activa', () async {
    final c = SesionControlador(_RepoFalso(hayGuardada: true));
    await c.iniciar();
    expect(c.estado, EstadoSesion.activa);
  });

  test('login correcto deja la sesión activa', () async {
    final c = SesionControlador(_RepoFalso());
    final ok = await c.iniciarSesion(' demo@correo.cl ', 'clave-larga-123');
    expect(ok, isTrue);
    expect(c.estado, EstadoSesion.activa);
    expect(c.email, 'demo@correo.cl');
    expect(c.error, isNull);
  });

  test('credenciales incorrectas muestran un mensaje claro', () async {
    final c =
        SesionControlador(_RepoFalso(fallo: const ErrorApi(401, 'x')));
    final ok = await c.iniciarSesion('demo@correo.cl', 'mala');
    expect(ok, isFalse);
    expect(c.estado, isNot(EstadoSesion.activa));
    expect(c.error, 'Correo o contraseña incorrectos.');
    expect(c.ocupado, isFalse);
  });

  test('un correo inválido ni siquiera llama al servidor', () async {
    final c = SesionControlador(_RepoFalso());
    final ok = await c.iniciarSesion('sin-arroba', 'clave');
    expect(ok, isFalse);
    expect(c.error, 'Escribe un correo válido.');
  });

  test('cerrar sesión limpia el estado', () async {
    final repo = _RepoFalso();
    final c = SesionControlador(repo);
    await c.iniciarSesion('demo@correo.cl', 'clave-larga-123');
    await c.cerrarSesion();
    expect(repo.cerro, isTrue);
    expect(c.estado, EstadoSesion.sinSesion);
    expect(c.email, isNull);
  });

  test('pedir recuperación con correo inválido devuelve mensaje', () async {
    final c = SesionControlador(_RepoFalso());
    expect(await c.solicitarRecuperacion('no-es-correo'), isNotNull);
  });

  test('pedir recuperación con correo válido no devuelve error', () async {
    final c = SesionControlador(_RepoFalso());
    expect(await c.solicitarRecuperacion('a@b.cl'), isNull);
  });

  test('restablecer muestra el mensaje del servidor si falla', () async {
    final c = SesionControlador(
        _RepoFalso(fallo: const ErrorApi(400, 'El enlace no sirve')));
    expect(await c.restablecerContrasena('x', 'abcd1234'), 'El enlace no sirve');
  });
}
