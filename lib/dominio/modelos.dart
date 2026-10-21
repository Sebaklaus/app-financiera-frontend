// Modelos del dominio. No dependen de Flutter ni de HTTP.

enum Categoria {
  necesidades('necesidades', 'Necesidades', 50),
  inversion('inversion', 'Inversión', 25),
  estabilidad('estabilidad', 'Estabilidad', 15),
  entretenimiento('entretenimiento', 'Entretenimiento', 10);

  const Categoria(this.clave, this.etiqueta, this.porcentaje);

  final String clave;
  final String etiqueta;
  final int porcentaje;

  /// El 25 % y el 15 % nunca se apartan sin que la persona lo confirme.
  bool get requiereConfirmacion =>
      this == Categoria.inversion || this == Categoria.estabilidad;

  static Categoria desde(String clave) => Categoria.values.firstWhere(
        (c) => c.clave == clave,
        orElse: () => Categoria.necesidades,
      );
}

int _entero(Object? valor) => (valor as num).toInt();

class Reparto {
  const Reparto({
    required this.necesidades,
    required this.inversion,
    required this.estabilidad,
    required this.entretenimiento,
  });

  factory Reparto.fromJson(Map<String, dynamic> j) => Reparto(
        necesidades: _entero(j['necesidades']),
        inversion: _entero(j['inversion']),
        estabilidad: _entero(j['estabilidad']),
        entretenimiento: _entero(j['entretenimiento']),
      );

  final int necesidades;
  final int inversion;
  final int estabilidad;
  final int entretenimiento;

  int de(Categoria c) => switch (c) {
        Categoria.necesidades => necesidades,
        Categoria.inversion => inversion,
        Categoria.estabilidad => estabilidad,
        Categoria.entretenimiento => entretenimiento,
      };

  int get total => necesidades + inversion + estabilidad + entretenimiento;
}

class IngresoRegistrado {
  const IngresoRegistrado({
    required this.id,
    required this.monto,
    required this.descripcion,
    required this.reparto,
  });

  factory IngresoRegistrado.fromJson(Map<String, dynamic> j) =>
      IngresoRegistrado(
        id: j['id'] as String,
        monto: _entero(j['monto']),
        descripcion: (j['descripcion'] ?? '') as String,
        reparto: Reparto.fromJson(j['reparto'] as Map<String, dynamic>),
      );

  final String id;
  final int monto;
  final String descripcion;
  final Reparto reparto;
}

class Confirmacion {
  const Confirmacion({
    required this.id,
    required this.categoria,
    required this.monto,
    required this.creadoEn,
  });

  factory Confirmacion.fromJson(Map<String, dynamic> j) => Confirmacion(
        id: j['id'] as String,
        categoria: Categoria.desde(j['categoria'] as String),
        monto: _entero(j['monto']),
        creadoEn: DateTime.parse(j['creado_en'] as String).toLocal(),
      );

  final String id;
  final Categoria categoria;
  final int monto;
  final DateTime creadoEn;
}

class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
  });

  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        monto: _entero(j['monto']),
        categoria: j['categoria'] == null
            ? null
            : Categoria.desde(j['categoria'] as String),
        descripcion: (j['descripcion'] ?? '') as String,
        fecha: (j['fecha'] ?? '') as String,
      );

  final String id;
  final String tipo; // 'ingreso' o 'gasto'
  final int monto;
  final Categoria? categoria;
  final String descripcion;
  final String fecha; // AAAA-MM-DD

  bool get esIngreso => tipo == 'ingreso';
}

class ResumenCategoria {
  const ResumenCategoria({
    required this.categoria,
    required this.asignado,
    required this.gastado,
    required this.disponible,
    required this.porConfirmar,
    required this.rechazado,
  });

  factory ResumenCategoria.fromJson(Map<String, dynamic> j) => ResumenCategoria(
        categoria: Categoria.desde(j['categoria'] as String),
        asignado: _entero(j['asignado']),
        gastado: _entero(j['gastado']),
        disponible: _entero(j['disponible']),
        porConfirmar: _entero(j['por_confirmar']),
        rechazado: _entero(j['rechazado']),
      );

  final Categoria categoria;
  final int asignado;
  final int gastado;
  final int disponible;
  final int porConfirmar;
  final int rechazado;
}

class Resumen {
  const Resumen({
    required this.ingresosTotal,
    required this.gastosTotal,
    required this.categorias,
  });

  factory Resumen.fromJson(Map<String, dynamic> j) => Resumen(
        ingresosTotal: _entero(j['ingresos_total']),
        gastosTotal: _entero(j['gastos_total']),
        categorias: (j['categorias'] as List<dynamic>)
            .map((e) => ResumenCategoria.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int ingresosTotal;
  final int gastosTotal;
  final List<ResumenCategoria> categorias;
}

class EstadoConsentimientos {
  const EstadoConsentimientos({
    required this.otorgados,
    required this.pendientes,
  });

  factory EstadoConsentimientos.fromJson(Map<String, dynamic> j) {
    final lista = (j['consentimientos'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>);
    return EstadoConsentimientos(
      otorgados: {
        for (final c in lista) c['tipo'] as String: (c['otorgado'] ?? false) as bool,
      },
      pendientes: (j['pendientes'] as List<dynamic>).cast<String>(),
    );
  }

  final Map<String, bool> otorgados;
  final List<String> pendientes;

  bool get completo => pendientes.isEmpty;
}

class CuentaBancaria {
  const CuentaBancaria({
    required this.id,
    required this.nombre,
    required this.numeroEnmascarado,
    required this.moneda,
    required this.saldo,
  });

  factory CuentaBancaria.fromJson(Map<String, dynamic> j) => CuentaBancaria(
        id: j['id'] as String,
        nombre: (j['nombre'] ?? 'Cuenta') as String,
        numeroEnmascarado: (j['numero_enmascarado'] ?? '') as String,
        moneda: (j['moneda'] ?? 'CLP') as String,
        saldo: j['saldo'] == null ? null : _entero(j['saldo']),
      );

  final String id;
  final String nombre;
  final String numeroEnmascarado;
  final String moneda;
  final int? saldo; // el banco puede no informarlo
}

/// Movimiento tal como lo informa el banco (positivo = abono, negativo = cargo).
class MovimientoBanco {
  const MovimientoBanco({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.descripcion,
  });

  factory MovimientoBanco.fromJson(Map<String, dynamic> j) => MovimientoBanco(
        id: j['id'] as String,
        fecha: (j['fecha'] ?? '') as String,
        monto: _entero(j['monto']),
        descripcion: (j['descripcion'] ?? '') as String,
      );

  final String id;
  final String fecha;
  final int monto;
  final String descripcion;

  bool get esAbono => monto > 0;
}

class ResultadoImportacion {
  const ResultadoImportacion({
    required this.importados,
    required this.yaImportados,
    required this.cargosOmitidos,
  });

  factory ResultadoImportacion.fromJson(Map<String, dynamic> j) =>
      ResultadoImportacion(
        importados: _entero(j['importados']),
        yaImportados: _entero(j['ya_importados']),
        cargosOmitidos: _entero(j['cargos_omitidos']),
      );

  final int importados;
  final int yaImportados;
  final int cargosOmitidos;
}
