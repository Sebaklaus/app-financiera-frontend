import 'package:flutter/material.dart';

import '../dominio/lecciones.dart';
import 'widgets/contenido_centrado.dart';

/// Módulo educativo básico (plan Free).
class PaginaAprender extends StatelessWidget {
  const PaginaAprender({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ContenidoCentrado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Aprende finanzas básicas',
              style: tema.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Lecciones cortas para entender cómo funciona tu reparto.'),
          const SizedBox(height: 12),
          for (final l in lecciones)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(l.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l.resumen),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final p in l.puntos)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 10),
                            child: Icon(Icons.circle, size: 6),
                          ),
                          Expanded(child: Text(p)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
              'Contenido educativo general. No constituye asesoría financiera ni de inversión.',
              style: tema.textTheme.bodySmall),
        ],
      ),
    );
  }
}
