import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/cuenta_controlador.dart';
import '../estado/sesion_controlador.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'widgets/aviso_error.dart';
import 'widgets/contenido_centrado.dart';

/// Mi cuenta: lo que la app guarda de ti, tu actividad de seguridad, cambio de contraseña
/// y eliminación de la cuenta (derechos de la Ley 21.719).
class PaginaCuenta extends StatefulWidget {
  const PaginaCuenta({super.key});

  @override
  State<PaginaCuenta> createState() => _PaginaCuentaState();
}

class _PaginaCuentaState extends State<PaginaCuenta> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetida = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CuentaControlador>().cargar();
    });
  }

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetida.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    final cuenta = context.read<CuentaControlador>();
    final sesion = context.read<SesionControlador>();
    final ok = await cuenta.cambiarContrasena(_actual.text, _nueva.text, _repetida.text);
    if (ok && mounted) {
      // El servidor cerró todas las sesiones: se vuelve a la pantalla de entrada.
      await sesion.cerrarSesion();
    }
  }

  Future<void> _eliminar() async {
    final cuenta = context.read<CuentaControlador>();
    final sesion = context.read<SesionControlador>();
    final clave = TextEditingController();
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Se borran tu cuenta y TODOS tus datos (movimientos, metas, '
                'consentimientos). No se puede deshacer.'),
            const SizedBox(height: 12),
            TextField(
              controller: clave,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Tu contraseña para confirmar'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colores.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar para siempre'),
          ),
        ],
      ),
    );
    final texto = clave.text;
    if (seguro != true || !mounted) return;
    final ok = await cuenta.eliminarCuenta(texto);
    if (ok && mounted) await sesion.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CuentaControlador>();
    final tema = Theme.of(context);
    final titulo = tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final d = c.datos;
    return RefreshIndicator(
      onRefresh: c.cargar,
      child: ContenidoCentrado(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Mi cuenta',
                style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (c.error != null) AvisoError(c.error!),
            if (c.cargando && d == null)
              const Center(child: CircularProgressIndicator())
            else if (d != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lo que la app guarda de ti', style: titulo),
                      const SizedBox(height: 8),
                      Text('Correo: ${d.email}'),
                      Text('Cuenta creada: ${fechaHora(d.creadoEn)}'),
                      Text('Perfil de riesgo: ${d.perfilRiesgo ?? 'sin declarar'}'),
                      Text('Movimientos: ${d.movimientos}'),
                      Text('Propuestas de reparto: ${d.confirmaciones}'),
                      Text('Consentimientos registrados: ${d.consentimientos}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu actividad de seguridad', style: titulo),
                    const SizedBox(height: 4),
                    if (c.actividad.isEmpty) const Text('Aún no hay actividad.'),
                    for (final e in c.actividad)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.etiqueta),
                        subtitle: Text(fechaHora(e.fecha)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Cambiar contraseña', style: titulo),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _actual,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña actual'),
                    ),
                    TextField(
                      controller: _nueva,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña nueva'),
                    ),
                    TextField(
                      controller: _repetida,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Repite la contraseña nueva'),
                    ),
                    const SizedBox(height: 4),
                    Text('Al cambiarla se cierran todas tus sesiones y tendrás que entrar de nuevo.',
                        style: tema.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: c.ocupado ? null : _cambiar,
                      child: const Text('Cambiar contraseña'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: c.ocupado ? null : _eliminar,
              style: OutlinedButton.styleFrom(foregroundColor: Colores.error),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Eliminar mi cuenta y mis datos'),
            ),
          ],
        ),
      ),
    );
  }
}
