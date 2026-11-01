import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/metas_controlador.dart';
import '../nucleo/formato.dart';
import 'widgets/aviso_error.dart';
import 'widgets/barra_progreso_meta.dart';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Hoja para crear una meta nueva.
class HojaNuevaMeta extends StatefulWidget {
  const HojaNuevaMeta({super.key});

  @override
  State<HojaNuevaMeta> createState() => _HojaNuevaMetaState();
}

class _HojaNuevaMetaState extends State<HojaNuevaMeta> {
  final _nombre = TextEditingController();
  final _monto = TextEditingController();
  DateTime? _limite;

  @override
  void initState() {
    super.initState();
    // Un error viejo de otra hoja no debe aparecer aquí.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MetasControlador>().error = null;
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _limite ?? hoy.add(const Duration(days: 30)),
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 20),
    );
    if (f != null) setState(() => _limite = f);
  }

  Future<void> _crear() async {
    final m = context.read<MetasControlador>();
    final ok = await m.crear(
      _nombre.text,
      parseMonto(_monto.text),
      fechaLimite: _limite == null ? null : _iso(_limite!),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MetasControlador>();
    final tema = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nueva meta',
              style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nombre,
            autofocus: true,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nombre (ej. Viaje a Chiloé)'),
          ),
          TextField(
            controller: _monto,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto que quieres juntar', prefixText: '\$ '),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _elegirFecha,
            icon: const Icon(Icons.event),
            label: Text(_limite == null
                ? 'Fecha límite (opcional)'
                : 'Para el ${fechaCorta(_iso(_limite!))}'),
          ),
          if (m.error != null) ...[
            const SizedBox(height: 12),
            AvisoError(m.error!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: m.ocupado ? null : _crear,
            child: m.ocupado
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Crear meta'),
          ),
        ],
      ),
    );
  }
}

/// Hoja con el avance de una meta, el historial y el formulario de aporte.
class HojaDetalleMeta extends StatefulWidget {
  const HojaDetalleMeta({super.key});

  @override
  State<HojaDetalleMeta> createState() => _HojaDetalleMetaState();
}

class _HojaDetalleMetaState extends State<HojaDetalleMeta> {
  final _monto = TextEditingController();

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _aportar(String id) async {
    final ok = await context.read<MetasControlador>().aportar(id, parseMonto(_monto.text));
    if (ok) _monto.clear();
  }

  Future<void> _borrar(String id) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar esta meta?'),
        content: const Text('Se borran también sus aportes. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (seguro != true || !mounted) return;
    final ok = await context.read<MetasControlador>().eliminar(id);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MetasControlador>();
    final meta = m.abierta;
    final tema = Theme.of(context);
    if (meta == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(meta.nombre,
              style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          BarraProgresoMeta(porcentaje: meta.porcentaje, cumplida: meta.cumplida),
          const SizedBox(height: 8),
          Text(meta.cumplida
              ? '¡Meta cumplida! Llevas ${clp(meta.ahorrado)} de ${clp(meta.montoObjetivo)}.'
              : 'Llevas ${clp(meta.ahorrado)} de ${clp(meta.montoObjetivo)} (${meta.porcentaje} %). '
                  'Faltan ${clp(meta.falta)}.'),
          if (meta.fechaLimite != null)
            Text('Fecha límite: ${fechaCorta(meta.fechaLimite!)}', style: tema.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _monto,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _aportar(meta.id),
            decoration: const InputDecoration(
              labelText: 'Anotar un aporte (lo que apartaste)',
              prefixText: '\$ ',
            ),
          ),
          if (m.error != null) ...[
            const SizedBox(height: 12),
            AvisoError(m.error!),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: m.ocupado ? null : () => _aportar(meta.id),
            child: const Text('Anotar aporte'),
          ),
          const SizedBox(height: 4),
          Text('La app no mueve dinero: solo anota lo que tú dices haber apartado.',
              style: tema.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Historial', style: tema.textTheme.titleMedium),
          if (meta.aportes.isEmpty) const Text('Todavía no hay aportes.'),
          for (final a in meta.aportes.take(20))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(clp(a.monto)),
              subtitle: Text(fechaCorta(a.fecha)),
            ),
          TextButton.icon(
            onPressed: m.ocupado ? null : () => _borrar(meta.id),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Borrar meta'),
          ),
        ],
      ),
    );
  }
}
