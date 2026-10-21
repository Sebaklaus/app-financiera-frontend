import 'package:flutter/material.dart';

import 'app.dart';
import 'datos/almacen_sesion.dart';
import 'datos/cliente_api.dart';
import 'datos/repositorio_auth.dart';
import 'estado/sesion_controlador.dart';
import 'nucleo/config.dart';

/// Aquí se "arma" la app: se crean las piezas y se conectan entre sí.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ClienteApi(urlBase: Config.urlApi, almacen: AlmacenSesionSeguro());
  final sesion = SesionControlador(RepositorioAuthApi(api));
  api.alExpirarSesion = sesion.sesionExpirada;
  sesion.iniciar();

  runApp(AppFinanciera(api: api, sesion: sesion));
}
