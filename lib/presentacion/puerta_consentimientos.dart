import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/consentimientos_controlador.dart';
import '../estado/sesion_controlador.dart';
import 'pantalla_consentimientos.dart';
import 'pantalla_principal.dart';

/// Deja pasar a la app solo cuando los consentimientos obligatorios están
/// otorgados.
class PuertaConsentimientos extends StatelessWidget {
  const PuertaConsentimientos({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConsentimientosControlador>();
    if (c.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (c.completo) return const PantallaPrincipal();
    if (c.error != null && !c.terminos && !c.datosFinancieros) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: c.cargar, child: const Text('Reintentar')),
                TextButton(
                  onPressed: () => context.read<SesionControlador>().cerrarSesion(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const PantallaConsentimientos();
  }
}
