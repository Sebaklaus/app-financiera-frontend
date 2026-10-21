import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/consentimientos_controlador.dart';
import '../estado/sesion_controlador.dart';
import 'widgets/aviso_error.dart';
import 'widgets/contenido_centrado.dart';

/// Primer paso tras registrarse: consentimientos por separado y perfil de riesgo.
class PantallaConsentimientos extends StatelessWidget {
  const PantallaConsentimientos({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConsentimientosControlador>();
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antes de empezar'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SesionControlador>().cerrarSesion(),
          ),
        ],
      ),
      body: ContenidoCentrado(
        ancho: 560,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Tus datos, tus reglas',
                style: tema.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Cada autorización se pide por separado y puedes cambiarla después. '
              'La aplicación nunca mueve tu dinero: solo propone y tú decides.',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: c.terminos,
              onChanged: (v) => c.cambiar(terminos: v),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Términos y política de privacidad'),
              subtitle: const Text('Obligatorio'),
            ),
            CheckboxListTile(
              value: c.datosFinancieros,
              onChanged: (v) => c.cambiar(datosFinancieros: v),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Uso de mis datos financieros'),
              subtitle: const Text('Obligatorio: para calcular tu reparto y tu resumen'),
            ),
            CheckboxListTile(
              value: c.comunicaciones,
              onChanged: (v) => c.cambiar(comunicaciones: v),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Recibir comunicaciones'),
              subtitle: const Text('Opcional'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: c.perfil,
              decoration: const InputDecoration(labelText: 'Perfil de riesgo'),
              items: const [
                DropdownMenuItem(value: 'conservador', child: Text('Conservador')),
                DropdownMenuItem(value: 'moderado', child: Text('Moderado')),
                DropdownMenuItem(value: 'arriesgado', child: Text('Arriesgado')),
              ],
              onChanged: (v) => c.cambiar(perfil: v),
            ),
            const SizedBox(height: 16),
            if (c.error != null) AvisoError(c.error!),
            FilledButton(
              onPressed: c.ocupado ? null : c.guardar,
              child: c.ocupado
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Guardar y continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
