import 'package:app_financiera/datos/repositorio_banco.dart';
import 'package:app_financiera/dominio/lecciones.dart';
import 'package:app_financiera/dominio/modelos.dart';
import 'package:app_financiera/estado/banco_controlador.dart';
import 'package:app_financiera/nucleo/errores.dart';
import 'package:flutter_test/flutter_test.dart';

const _cuenta = CuentaBancaria(
  id: 'acc_1',
  nombre: 'Cuenta Corriente',
  numeroEnmascarado: '····1234',
  moneda: 'CLP',
  saldo: 500000,
);

class _RepoFalso implements RepositorioBanco {
  bool conectado = false;
  ErrorApi? fallo;

  @override
  Future<List<CuentaBancaria>?> cuentas() async => conectado ? [_cuenta] : null;

  @override
  Future<List<CuentaBancaria>> conectar(String linkToken) async {
    if (fallo != null) throw fallo!;
    conectado = true;
    return [_cuenta];
  }

  @override
  Future<void> desconectar() async => conectado = false;

  @override
  Future<List<MovimientoBanco>> movimientos(String cuentaId) async => const [
        MovimientoBanco(id: 'm1', fecha: '2026-10-01', monto: 1000000, descripcion: 'Sueldo'),
        MovimientoBanco(id: 'm2', fecha: '2026-10-02', monto: -45000, descripcion: 'Super'),
      ];

  @override
  Future<ResultadoImportacion> importar(String cuentaId) async =>
      const ResultadoImportacion(importados: 1, yaImportados: 0, cargosOmitidos: 1);
}

void main() {
  test('sin banco conectado, cargar deja cuentas en null', () async {
    final b = BancoControlador(_RepoFalso(), alImportar: () async {});
    await b.cargar();
    expect(b.conectado, isFalse);
    expect(b.error, isNull);
  });

  test('un enlace vacío no llama al servidor', () async {
    final repo = _RepoFalso();
    final b = BancoControlador(repo, alImportar: () async {});
    final ok = await b.conectar('   ');
    expect(ok, isFalse);
    expect(repo.conectado, isFalse);
    expect(b.error, isNotNull);
  });

  test('conectar guarda las cuentas y avisa', () async {
    final b = BancoControlador(_RepoFalso(), alImportar: () async {});
    expect(await b.conectar(' link_abc_token_xyz '), isTrue);
    expect(b.conectado, isTrue);
    expect(b.cuentas!.single.nombre, 'Cuenta Corriente');
    expect(b.aviso, contains('cifrado'));
  });

  test('un enlace inválido muestra el error del servidor', () async {
    final repo = _RepoFalso()..fallo = const ErrorApi(422, 'Enlace bancario inválido');
    final b = BancoControlador(repo, alImportar: () async {});
    expect(await b.conectar('link_malo'), isFalse);
    expect(b.error, 'Enlace bancario inválido');
    expect(b.conectado, isFalse);
  });

  test('importar avisa a las finanzas para que recarguen', () async {
    var recargas = 0;
    final b = BancoControlador(_RepoFalso(), alImportar: () async => recargas++);
    await b.conectar('link_ok');
    await b.verMovimientos(b.cuentas!.first);
    expect(b.movimientos, hasLength(2));
    expect(await b.importar(), isTrue);
    expect(recargas, 1);
    expect(b.aviso, contains('Importados: 1'));
  });

  test('importar sin cuenta elegida no hace nada', () async {
    final b = BancoControlador(_RepoFalso(), alImportar: () async {});
    expect(await b.importar(), isFalse);
  });

  test('desconectar borra el estado local', () async {
    final b = BancoControlador(_RepoFalso(), alImportar: () async {});
    await b.conectar('link_ok');
    await b.desconectar();
    expect(b.conectado, isFalse);
    expect(b.movimientos, isEmpty);
  });

  test('las lecciones tienen contenido', () {
    expect(lecciones, isNotEmpty);
    for (final l in lecciones) {
      expect(l.titulo, isNotEmpty);
      expect(l.puntos, isNotEmpty);
    }
  });

  test('CuentaBancaria acepta saldo nulo y un abono se distingue de un cargo', () {
    final c = CuentaBancaria.fromJson({
      'id': 'a',
      'nombre': 'X',
      'numero_enmascarado': '····1',
      'moneda': 'CLP',
      'saldo': null,
    });
    expect(c.saldo, isNull);
    const abono = MovimientoBanco(id: '1', fecha: '', monto: 10, descripcion: '');
    const cargo = MovimientoBanco(id: '2', fecha: '', monto: -10, descripcion: '');
    expect(abono.esAbono, isTrue);
    expect(cargo.esAbono, isFalse);
  });
}
