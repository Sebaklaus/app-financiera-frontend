import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/modelos.dart';
import '../estado/finanzas_controlador.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'hoja_gasto.dart';
import 'hoja_ingreso.dart';
import 'widgets/aviso_error.dart';
import 'widgets/contenido_centrado.dart';

/// Resumen por categoría y accesos para registrar ingresos y gastos.
class PaginaInicio extends StatelessWidget {
  const PaginaInicio({super.key, required this.irAConfirmaciones});

  final VoidCallback irAConfirmaciones;

  void _abrirIngreso(BuildContext context) {
    final f = context.read<FinanzasControlador>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ChangeNotifierProvider<FinanzasControlador>.value(
        value: f,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: HojaIngreso(
            alVerConfirmaciones: () {
              Navigator.of(ctx).pop();
              irAConfirmaciones();
            },
          ),
        ),
      ),
    );
  }

  void _abrirGasto(BuildContext context) {
    final f = context.read<FinanzasControlador>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ChangeNotifierProvider<FinanzasControlador>.value(
        value: f,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: const HojaGasto(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanzasControlador>();
    final r = f.resumen;
    final tema = Theme.of(context);
    return RefreshIndicator(
      onRefresh: f.cargar,
      child: ContenidoCentrado(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (f.error != null) AvisoError(f.error!),
            if (f.pendientes.isNotEmpty)
              Card(
                color: tema.colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(
                      'Tienes ${f.pendientes.length} decisión(es) pendiente(s)'),
                  subtitle: const Text(
                      'El 25 % y el 15 % solo se apartan si tú lo confirmas.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: irAConfirmaciones,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _abrirIngreso(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ingreso'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirGasto(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.remove),
                    label: const Text('Gasto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (r == null && f.cargando)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (r != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _Total('Ingresos', clp(r.ingresosTotal))),
                      Expanded(child: _Total('Gastos', clp(r.gastosTotal))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final c in r.categorias) _TarjetaCategoria(c),
            ],
          ],
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.titulo, this.valor);

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(titulo, style: tema.labelLarge),
        const SizedBox(height: 4),
        Text(valor,
            style: tema.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TarjetaCategoria extends StatelessWidget {
  const _TarjetaCategoria(this.c);

  final ResumenCategoria c;

  @override
  Widget build(BuildContext context) {
    final color = colorCategoria(c.categoria);
    final tema = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${c.categoria.etiqueta} (${c.categoria.porcentaje} %)',
                      style: tema.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text(clp(c.disponible),
                    style: tema.titleMedium?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Asignado ${clp(c.asignado)} · Gastado ${clp(c.gastado)}',
                style: tema.bodyMedium),
            if (c.porConfirmar > 0)
              Text('Por confirmar ${clp(c.porConfirmar)}',
                  style: tema.bodyMedium?.copyWith(color: Colores.estabilidad)),
            if (c.rechazado > 0)
              Text('Sin apartar (rechazado) ${clp(c.rechazado)}',
                  style: tema.bodySmall),
          ],
        ),
      ),
    );
  }
}
