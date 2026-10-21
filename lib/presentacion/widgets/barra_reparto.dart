import 'package:flutter/material.dart';

import '../../dominio/modelos.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/tema.dart';

/// Barra 50/25/15/10 con la leyenda de montos.
class BarraReparto extends StatelessWidget {
  const BarraReparto({super.key, required this.reparto});

  final Reparto reparto;

  @override
  Widget build(BuildContext context) {
    final total = reparto.total == 0 ? 1 : reparto.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Reparto del ingreso: ${Categoria.values.map((c) => '${c.etiqueta} ${c.porcentaje} por ciento').join(', ')}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 22,
              child: LayoutBuilder(
                builder: (context, caja) => Row(
                  children: [
                    for (final c in Categoria.values)
                      Container(
                        width: caja.maxWidth * reparto.de(c) / total,
                        color: colorCategoria(c),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final c in Categoria.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorCategoria(c),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('${c.etiqueta} (${c.porcentaje} %)')),
                Text(clp(reparto.de(c)),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}
