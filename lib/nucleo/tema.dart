import 'package:flutter/material.dart';

import '../dominio/modelos.dart';

/// Colores y tema únicos de la app (los mismos de la demo web).
class Colores {
  static const Color primario = Color(0xFF1F4E79);
  static const Color necesidades = Color(0xFF2F6FA8);
  static const Color inversion = Color(0xFF1D7A4D);
  static const Color estabilidad = Color(0xFFB45309);
  static const Color entretenimiento = Color(0xFF7A4FB0);
  static const Color error = Color(0xFFB3261E);
}

Color colorCategoria(Categoria c) => switch (c) {
      Categoria.necesidades => Colores.necesidades,
      Categoria.inversion => Colores.inversion,
      Categoria.estabilidad => Colores.estabilidad,
      Categoria.entretenimiento => Colores.entretenimiento,
    };

ThemeData construirTema(Brightness brillo) {
  final esquema = ColorScheme.fromSeed(
    seedColor: Colores.primario,
    brightness: brillo,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
