import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/finanzas_controlador.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'widgets/aviso_error.dart';
import 'widgets/contenido_centrado.dart';

/// El 25 % (inversión) y el 15 % (estabilidad) se apartan solo si la persona
/// confirma. Rechazar deja ese dinero sin apartar.
class PaginaConfirmaciones extends StatelessWidget {
  const PaginaConfirmaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanzasControlador>();
    final tema = Theme.of(context);
    return RefreshIndicator(
      onRefresh: f.cargar,
      child: ContenidoCentrado(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Confirmaciones pendientes',
                style: tema.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
                'El dinero nunca pasa por la app: tú decides si lo apartas para inversión y estabilidad.'),
            const SizedBox(height: 12),
            if (f.error != null) AvisoError(f.error!),
            if (f.pendientes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('No tienes confirmaciones pendientes.')),
              ),
            for (final c in f.pendientes)
              Card(
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
                              color: colorCategoria(c.categoria),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                '${c.categoria.etiqueta} (${c.categoria.porcentaje} %)',
                                style: tema.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          Text(clp(c.monto),
                              style: tema.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Propuesto el ${fechaHora(c.creadoEn)}',
                          style: tema.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: f.ocupado
                                  ? null
                                  : () => f.decidir(c, confirmar: true),
                              child: const Text('Confirmar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: f.ocupado
                                  ? null
                                  : () => f.decidir(c, confirmar: false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Rechazar'),
                            ),
                          ),
                        ],
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
