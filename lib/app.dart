import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'datos/cliente_api.dart';
import 'datos/repositorio_banco.dart';
import 'datos/repositorio_consentimientos.dart';
import 'datos/repositorio_cuenta.dart';
import 'datos/repositorio_dashboard.dart';
import 'datos/repositorio_inversion.dart';
import 'datos/repositorio_finanzas.dart';
import 'datos/repositorio_metas.dart';
import 'estado/banco_controlador.dart';
import 'estado/consentimientos_controlador.dart';
import 'estado/cuenta_controlador.dart';
import 'estado/dashboard_controlador.dart';
import 'estado/finanzas_controlador.dart';
import 'estado/inversion_controlador.dart';
import 'estado/metas_controlador.dart';
import 'estado/sesion_controlador.dart';
import 'nucleo/tema.dart';
import 'presentacion/pantalla_login.dart';
import 'presentacion/puerta_consentimientos.dart';

class AppFinanciera extends StatelessWidget {
  const AppFinanciera({super.key, required this.api, required this.sesion});

  final ClienteApi api;
  final SesionControlador sesion;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ClienteApi>.value(value: api),
        ChangeNotifierProvider<SesionControlador>.value(value: sesion),
      ],
      child: MaterialApp(
        title: 'HelpFinance',
        debugShowCheckedModeBanner: false,
        theme: construirTema(Brightness.light),
        darkTheme: construirTema(Brightness.dark),
        home: const _Raiz(),
      ),
    );
  }
}

/// Decide qué pantalla mostrar según el estado de la sesión.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<SesionControlador>().estado;
    switch (estado) {
      case EstadoSesion.cargando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case EstadoSesion.sinSesion:
        return const PantallaLogin();
      case EstadoSesion.activa:
        return const _ZonaAutenticada();
    }
  }
}

/// Todo lo que solo existe con sesión iniciada. Al cerrar sesión este widget se
/// destruye y con él los controladores, así no quedan datos de la persona anterior.
class _ZonaAutenticada extends StatelessWidget {
  const _ZonaAutenticada();

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClienteApi>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConsentimientosControlador>(
          create: (_) =>
              ConsentimientosControlador(RepositorioConsentimientosApi(api))
                ..cargar(),
        ),
        ChangeNotifierProvider<DashboardControlador>(
          create: (_) => DashboardControlador(RepositorioDashboardApi(api)),
        ),
        ChangeNotifierProvider<FinanzasControlador>(
          create: (ctx) => FinanzasControlador(
            RepositorioFinanzasApi(api),
            alActualizar: ctx.read<DashboardControlador>().cargar,
          ),
        ),
        ChangeNotifierProvider<BancoControlador>(
          create: (ctx) => BancoControlador(
            RepositorioBancoApi(api),
            alImportar: ctx.read<FinanzasControlador>().cargar,
          ),
        ),
        ChangeNotifierProvider<InversionControlador>(
          create: (_) => InversionControlador(RepositorioInversionApi(api)),
        ),
        ChangeNotifierProvider<CuentaControlador>(
          create: (_) => CuentaControlador(RepositorioCuentaApi(api)),
        ),
        ChangeNotifierProvider<MetasControlador>(
          create: (_) => MetasControlador(RepositorioMetasApi(api)),
        ),
      ],
      child: const PuertaConsentimientos(),
    );
  }
}
