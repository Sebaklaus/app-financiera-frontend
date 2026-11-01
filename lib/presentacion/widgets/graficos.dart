import 'package:flutter/material.dart';

import '../../dominio/modelos.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/tema.dart';

/// Barras de ingresos y gastos por mes. Dibujado con widgets simples (sin librerías),
/// con un texto equivalente para lectores de pantalla.
class GraficoTendencia extends StatelessWidget {
  const GraficoTendencia({super.key, required this.meses, required this.maximo});

  final List<MesTendencia> meses;
  final int maximo;

  static const double _alto = 140;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final resumen = meses
        .map((m) => '${m.etiqueta}: ingresos ${clp(m.ingresos)}, gastos ${clp(m.gastos)}')
        .join('; ');
    return Semantics(
      label: 'Gráfico de ingresos y gastos por mes. $resumen',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _alto + 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in meses)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: _alto,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _Barra(m.ingresos, maximo, Colores.inversion),
                                const SizedBox(width: 3),
                                _Barra(m.gastos, maximo, Colores.estabilidad),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(m.etiqueta, style: tema.textTheme.labelSmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                _Leyenda(Colores.inversion, 'Ingresos'),
                SizedBox(width: 16),
                _Leyenda(Colores.estabilidad, 'Gastos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra(this.valor, this.maximo, this.color);

  final int valor;
  final int maximo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraccion = maximo <= 0 ? 0.0 : (valor / maximo).clamp(0.0, 1.0);
    // Un valor pequeño pero mayor que cero se sigue viendo (mínimo 3 px).
    final double alto = valor > 0
        ? (GraficoTendencia._alto * fraccion).clamp(3.0, GraficoTendencia._alto).toDouble()
        : 0.0;
    return Container(
      width: 14,
      height: alto,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda(this.color, this.texto);

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Barras horizontales: en qué categorías se fue el gasto del mes.
class GraficoCategorias extends StatelessWidget {
  const GraficoCategorias({super.key, required this.gastos});

  final List<MapEntry<Categoria, int>> gastos;

  @override
  Widget build(BuildContext context) {
    final total = gastos.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) return const Text('Aún no registras gastos este mes.');
    return Column(
      children: [
        for (final e in gastos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Semantics(
              label: '${e.key.etiqueta}: ${clp(e.value)}, ${e.value * 100 ~/ total} por ciento del gasto',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.key.etiqueta)),
                        Text('${clp(e.value)} · ${e.value * 100 ~/ total} %'),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: e.value / total,
                        minHeight: 8,
                        color: colorCategoria(e.key),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
