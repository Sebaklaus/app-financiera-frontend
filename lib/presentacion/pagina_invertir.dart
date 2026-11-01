import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/modelos.dart';
import '../estado/finanzas_controlador.dart';
import '../estado/inversion_controlador.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'widgets/aviso_error.dart';
import 'widgets/contenido_centrado.dart';

/// Opciones de inversión según tu perfil y paso a la entidad socia (simulada).
/// La app nunca mueve dinero: solo muestra y redirige.
class PaginaInvertir extends StatefulWidget {
  const PaginaInvertir({super.key});

  @override
  State<PaginaInvertir> createState() => _PaginaInvertirState();
}

class _PaginaInvertirState extends State<PaginaInvertir> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InversionControlador>().cargar();
    });
  }

  int? _disponibleParaInvertir(Resumen? r) {
    if (r == null) return null;
    for (final c in r.categorias) {
      if (c.categoria == Categoria.inversion) return c.disponible;
    }
    return null;
  }

  Future<void> _ir(InstrumentoInversion i, int? sugerido) async {
    final controlador = context.read<InversionControlador>();
    final monto = TextEditingController(
        text: sugerido != null && sugerido > 0 ? '$sugerido' : '');
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ir a ${i.entidad.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vas a salir de la app hacia la entidad socia para contratar '
                '«${i.nombre}». Allí ingresas tus propias credenciales: la app no '
                've tu clave ni mueve dinero.'),
            const SizedBox(height: 12),
            TextField(
              controller: monto,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cuánto piensas invertir (opcional)',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    // El controlador no se libera aquí: el diálogo todavía se está cerrando con animación.
    final texto = monto.text;
    if (confirmado != true || !mounted) return;
    final ok = await controlador.derivar(i, monto: parseMonto(texto));
    if (ok && mounted) _mostrarResultado(controlador.ultima!);
  }

  void _mostrarResultado(DerivacionInversion d) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redirección a la entidad socia'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.simulada)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colores.estabilidad.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('SIMULACIÓN: todavía no hay convenio con entidades reales.',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 10),
              Text(d.instrumentoNombre, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(d.entidadNombre),
              if (d.monto != null) Text('Monto que pensabas invertir: ${clp(d.monto!)}'),
              const SizedBox(height: 10),
              Text(d.mensaje),
              const SizedBox(height: 10),
              const Text('Dirección de la entidad (simulada):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SelectableText(d.url),
              const SizedBox(height: 10),
              Text('Referencia: ${d.referencia}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              const Text('Quedó anotado en tu actividad (Más > Mi cuenta).'),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InversionControlador>();
    final finanzas = context.watch<FinanzasControlador>();
    final disponible = _disponibleParaInvertir(finanzas.resumen);
    final tema = Theme.of(context);
    final o = c.opciones;
    return RefreshIndicator(
      onRefresh: c.cargar,
      child: ContenidoCentrado(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Invertir',
                style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            if (disponible != null)
              Text('Tienes ${clp(disponible)} en tu categoría Inversión (25 %).'),
            const SizedBox(height: 8),
            if (c.error != null) AvisoError(c.error!),
            if (c.cargando && o == null)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (o != null) ...[
              _Perfil(o.perfilRiesgo),
              for (final i in o.opciones)
                _TarjetaInstrumento(
                  i,
                  ocupado: c.ocupado,
                  alIr: () => _ir(i, disponible),
                ),
              const SizedBox(height: 8),
              Text(o.aviso, style: tema.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Perfil extends StatelessWidget {
  const _Perfil(this.perfil);

  final String? perfil;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(perfil == null
            ? 'Aún no declaras tu perfil de riesgo, por eso no marcamos ninguna opción '
                'como recomendada.'
            : 'Tu perfil de riesgo: $perfil. Marcamos como «Recomendado» lo que no supera '
                'el riesgo que aceptas.'),
      ),
    );
  }
}

Color _colorRiesgo(String riesgo) => switch (riesgo) {
      'bajo' => Colores.inversion,
      'medio' => Colores.estabilidad,
      _ => Colores.error,
    };

class _TarjetaInstrumento extends StatelessWidget {
  const _TarjetaInstrumento(this.i, {required this.ocupado, required this.alIr});

  final InstrumentoInversion i;
  final bool ocupado;
  final VoidCallback alIr;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i.nombre,
                style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text('Riesgo ${i.riesgo}'),
                  side: BorderSide(color: _colorRiesgo(i.riesgo)),
                  visualDensity: VisualDensity.compact,
                ),
                if (i.recomendado)
                  const Chip(
                    avatar: Icon(Icons.check, size: 16),
                    label: Text('Recomendado para tu perfil'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(i.descripcion),
            const SizedBox(height: 6),
            Text('Plazo: ${i.plazo}', style: tema.textTheme.bodySmall),
            Text('Liquidez: ${i.liquidez}', style: tema.textTheme.bodySmall),
            Text('Entidad: ${i.entidad.nombre}', style: tema.textTheme.bodySmall),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: ocupado ? null : alIr,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ir a la entidad socia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
