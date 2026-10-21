import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';

class AvisoError extends StatelessWidget {
  const AvisoError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colores.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colores.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colores.error, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
  }
}
