import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';

/// Barra de avance de una meta, con texto para lectores de pantalla.
class BarraProgresoMeta extends StatelessWidget {
  const BarraProgresoMeta({super.key, required this.porcentaje, required this.cumplida});

  final int porcentaje;
  final bool cumplida;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Avance de la meta',
      value: '$porcentaje por ciento',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: porcentaje.clamp(0, 100) / 100,
          minHeight: 10,
          color: cumplida ? Colores.inversion : Colores.primario,
        ),
      ),
    );
  }
}
