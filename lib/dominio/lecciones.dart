/// Contenido educativo básico del plan Free. Es material informativo general,
/// no asesoría financiera ni de inversión.
class Leccion {
  const Leccion({
    required this.titulo,
    required this.resumen,
    required this.puntos,
  });

  final String titulo;
  final String resumen;
  final List<String> puntos;
}

const List<Leccion> lecciones = [
  Leccion(
    titulo: 'La regla 50/25/15/10',
    resumen: 'Una forma simple de repartir cada ingreso apenas llega.',
    puntos: [
      '50 % para necesidades: arriendo, cuentas, comida, transporte.',
      '25 % para inversión: dinero que dejas trabajando a largo plazo.',
      '15 % para estabilidad: tu colchón para imprevistos.',
      '10 % para entretenimiento: gustos que hacen sostenible el hábito.',
      'Separar estabilidad de inversión evita que una emergencia te obligue a '
          'vender algo que querías mantener; y dejar un 10 % para gustos hace '
          'más probable que sigas la regla en el tiempo.',
      'Son proporciones de partida: puedes ajustarlas a tu realidad.',
    ],
  ),
  Leccion(
    titulo: 'Fondo de emergencia',
    resumen: 'Tu colchón frente a un imprevisto, sin endeudarte.',
    puntos: [
      'Es dinero reservado para gastos inesperados: salud, reparaciones, '
          'pérdida de ingresos.',
      'Suele recomendarse reunir entre 3 y 6 meses de tus gastos básicos.',
      'Debe ser fácil de rescatar, por eso conviene que no esté en algo que '
          'pueda perder valor de un día para otro.',
      'En la app, el 15 % de estabilidad va dirigido a construirlo poco a poco.',
    ],
  ),
  Leccion(
    titulo: 'Gastos hormiga',
    resumen: 'Gastos pequeños y frecuentes que pasan desapercibidos.',
    puntos: [
      'Un café, un delivery o una suscripción parecen poco, pero se repiten.',
      'Sumar un mes completo te muestra su efecto real en tu presupuesto.',
      'Registrar tus gastos por categoría es el primer paso para verlos.',
      'No se trata de eliminarlos todos: se trata de decidirlos con conciencia.',
    ],
  ),
  Leccion(
    titulo: 'Invertir sin que la app toque tu dinero',
    resumen: 'Cómo funciona la inversión dentro de esta aplicación.',
    puntos: [
      'La app propone cuánto apartar, pero tú decides si lo confirmas.',
      'Tu dinero nunca pasa por la app: si invertes, lo haces directamente '
          'en la entidad financiera que elijas.',
      'Todo instrumento de inversión tiene riesgo; conocer tu perfil '
          '(conservador, moderado o arriesgado) ayuda a elegir con criterio.',
      'Esta información es educativa y general: no constituye asesoría de '
          'inversión.',
    ],
  ),
];
