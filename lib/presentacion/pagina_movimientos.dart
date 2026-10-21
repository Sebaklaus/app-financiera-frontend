import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/modelos.dart';
import '../estado/finanzas_controlador.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'widgets/aviso_error.dart';
import 'widgets/contenido_centrado.dart';

class PaginaMovimientos extends StatelessWidget {
  const PaginaMovimientos({super.key});

  Future<void> _eliminar(BuildContext context, Movimiento m) async {
    final f = context.read<FinanzasControlador>();
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text(
            '¿Eliminar "${m.descripcion}" por ${clp(m.monto)}? Se recalcula tu resumen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (seguro == true) await f.eliminarMovimiento(m);
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanzasControlador>();
    return RefreshIndicator(
      onRefresh: f.cargar,
      child: ContenidoCentrado(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (f.error != null) AvisoError(f.error!),
            if (f.movimientos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('Aún no tienes movimientos.')),
              ),
            for (final m in f.movimientos)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(
                    m.esIngreso ? Icons.south_west : Icons.north_east,
                    color: m.esIngreso ? Colores.inversion : Colores.error,
                  ),
                  title: Text(m.descripcion.isEmpty ? m.tipo : m.descripcion),
                  subtitle: Text(
                      '${fechaCorta(m.fecha)}${m.categoria == null ? '' : ' · ${m.categoria!.etiqueta}'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${m.esIngreso ? '+' : '-'}${clp(m.monto)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: m.esIngreso ? Colores.inversion : Colores.error,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: f.ocupado ? null : () => _eliminar(context, m),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
