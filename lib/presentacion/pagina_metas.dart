import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/modelos.dart';
import '../estado/metas_controlador.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'hoja_meta.dart';
import 'widgets/aviso_error.dart';
import 'widgets/barra_progreso_meta.dart';
import 'widgets/contenido_centrado.dart';

/// Lista de metas de ahorro. Al tocar una se abre su detalle con los aportes.
class PaginaMetas extends StatelessWidget {
  const PaginaMetas({super.key});

  void _hoja(BuildContext context, Widget Function() hoja) {
    final m = context.read<MetasControlador>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ChangeNotifierProvider<MetasControlador>.value(
        value: m,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: hoja(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MetasControlador>();
    final tema = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _hoja(context, () => const HojaNuevaMeta()),
        icon: const Icon(Icons.add),
        label: const Text('Nueva meta'),
      ),
      body: RefreshIndicator(
        onRefresh: m.cargar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Text('Tus metas',
                  style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                  'Anota lo que vas apartando. La app no mueve dinero: solo lleva la cuenta.'),
              const SizedBox(height: 12),
              if (m.error != null) AvisoError(m.error!),
              if (m.cargando && m.metas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (m.metas.isEmpty)
                const _SinMetas()
              else ...[
                _Resumen(m),
                for (final meta in m.metas)
                  _TarjetaMeta(
                    meta,
                    alTocar: () async {
                      if (await m.abrir(meta.id) && context.mounted) {
                        _hoja(context, () => const HojaDetalleMeta());
                      }
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SinMetas extends StatelessWidget {
  const _SinMetas();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 40),
            SizedBox(height: 8),
            Text('Aún no tienes metas', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text(
              'Crea una (un viaje, un fondo de emergencia, un computador) y mira cómo avanza.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen(this.m);

  final MetasControlador m;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      color: tema.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Llevas ahorrado'),
                  Text(clp(m.totalAhorrado),
                      style: tema.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Text('${m.cumplidas} de ${m.metas.length} cumplidas'),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMeta extends StatelessWidget {
  const _TarjetaMeta(this.meta, {required this.alTocar});

  final MetaAhorro meta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(meta.nombre,
                        style: tema.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (meta.cumplida)
                    const Icon(Icons.check_circle, color: Colores.inversion)
                  else
                    Text('${meta.porcentaje} %'),
                ],
              ),
              const SizedBox(height: 8),
              BarraProgresoMeta(porcentaje: meta.porcentaje, cumplida: meta.cumplida),
              const SizedBox(height: 8),
              Text(meta.cumplida
                  ? '¡Meta cumplida! ${clp(meta.ahorrado)} de ${clp(meta.montoObjetivo)}'
                  : '${clp(meta.ahorrado)} de ${clp(meta.montoObjetivo)} · faltan ${clp(meta.falta)}'),
              if (meta.fechaLimite != null)
                Text('Para el ${fechaCorta(meta.fechaLimite!)}',
                    style: tema.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
