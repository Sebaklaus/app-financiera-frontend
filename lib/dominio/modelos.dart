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

/// Un aporte a una meta: lo que la persona dice haber apartado (la app no mueve dinero).
class AporteMeta {
  const AporteMeta({required this.id, required this.monto, required this.fecha});

  factory AporteMeta.fromJson(Map<String, dynamic> j) => AporteMeta(
        id: j['id'] as String,
        monto: _entero(j['monto']),
        fecha: j['fecha'] as String,
      );

  final String id;
  final int monto;
  final String fecha;
}

/// Una meta de ahorro con su avance ya calculado por el servidor.
class MetaAhorro {
  const MetaAhorro({
    required this.id,
    required this.nombre,
    required this.montoObjetivo,
    required this.fechaLimite,
    required this.ahorrado,
    required this.falta,
    required this.porcentaje,
    required this.cumplida,
    this.aportes = const [],
  });

  factory MetaAhorro.fromJson(Map<String, dynamic> j) => MetaAhorro(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        montoObjetivo: _entero(j['monto_objetivo']),
        fechaLimite: j['fecha_limite'] as String?,
        ahorrado: _entero(j['ahorrado']),
        falta: _entero(j['falta']),
        porcentaje: _entero(j['porcentaje']),
        cumplida: j['cumplida'] as bool,
        aportes: ((j['aportes'] as List<dynamic>?) ?? const [])
            .map((e) => AporteMeta.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String nombre;
  final int montoObjetivo;
  final String? fechaLimite;
  final int ahorrado;
  final int falta;
  final int porcentaje;
  final bool cumplida;
  final List<AporteMeta> aportes;
}

/// Ingresos y gastos de un mes, para los gráficos del panel.
class MesTendencia {
  const MesTendencia({
    required this.mes,
    required this.ingresos,
    required this.gastos,
    required this.balance,
    required this.gastosPorCategoria,
  });

  factory MesTendencia.fromJson(Map<String, dynamic> j) {
    final crudo = (j['gastos_por_categoria'] as Map<String, dynamic>?) ?? const {};
    return MesTendencia(
      mes: j['mes'] as String,
      ingresos: _entero(j['ingresos']),
      gastos: _entero(j['gastos']),
      balance: _entero(j['balance']),
      gastosPorCategoria: {
        for (final c in Categoria.values) c: _entero(crudo[c.clave] ?? 0),
      },
    );
  }

  /// AAAA-MM
  final String mes;
  final int ingresos;
  final int gastos;
  final int balance;
  final Map<Categoria, int> gastosPorCategoria;

  static const _nombres = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// "2026-10" -> "oct". Si el texto no tiene el formato esperado lo devuelve igual.
  String get etiqueta {
    final p = mes.split('-');
    final n = p.length == 2 ? int.tryParse(p[1]) : null;
    return (n != null && n >= 1 && n <= 12) ? _nombres[n - 1] : mes;
  }
}

/// Entidad socia a la que se deriva la inversión (simulada por ahora).
class EntidadInversion {
  const EntidadInversion({required this.id, required this.nombre});

  factory EntidadInversion.fromJson(Map<String, dynamic> j) =>
      EntidadInversion(id: j['id'] as String, nombre: j['nombre'] as String);

  final String id;
  final String nombre;
}

/// Una opción del catálogo de inversión. Es información educativa: no se compra aquí.
class InstrumentoInversion {
  const InstrumentoInversion({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.riesgo,
    required this.plazo,
    required this.liquidez,
    required this.descripcion,
    required this.entidad,
    required this.recomendado,
  });

  factory InstrumentoInversion.fromJson(Map<String, dynamic> j) => InstrumentoInversion(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        tipo: j['tipo'] as String,
        riesgo: j['riesgo'] as String,
        plazo: j['plazo'] as String,
        liquidez: j['liquidez'] as String,
        descripcion: j['descripcion'] as String,
        entidad: EntidadInversion.fromJson(j['entidad'] as Map<String, dynamic>),
        recomendado: j['recomendado'] as bool,
      );

  final String id;
  final String nombre;
  final String tipo;

  /// bajo | medio | alto
  final String riesgo;
  final String plazo;
  final String liquidez;
  final String descripcion;
  final EntidadInversion entidad;
  final bool recomendado;
}

class OpcionesInversion {
  const OpcionesInversion({
    required this.perfilRiesgo,
    required this.opciones,
    required this.aviso,
  });

  factory OpcionesInversion.fromJson(Map<String, dynamic> j) => OpcionesInversion(
        perfilRiesgo: j['perfil_riesgo'] as String?,
        opciones: (j['opciones'] as List<dynamic>)
            .map((e) => InstrumentoInversion.fromJson(e as Map<String, dynamic>))
            .toList(),
        aviso: j['aviso'] as String,
      );

  /// null = todavía no declaró su perfil.
  final String? perfilRiesgo;
  final List<InstrumentoInversion> opciones;
  final String aviso;
}

/// Resultado de "ir a la entidad socia". Mientras no haya convenios, es una simulación.
class DerivacionInversion {
  const DerivacionInversion({
    required this.referencia,
    required this.instrumentoNombre,
    required this.entidadNombre,
    required this.url,
    required this.monto,
    required this.simulada,
    required this.mensaje,
  });

  factory DerivacionInversion.fromJson(Map<String, dynamic> j) => DerivacionInversion(
        referencia: j['referencia'] as String,
        instrumentoNombre: j['instrumento_nombre'] as String,
        entidadNombre: (j['entidad'] as Map<String, dynamic>)['nombre'] as String,
        url: j['url'] as String,
        monto: j['monto'] == null ? null : _entero(j['monto']),
        simulada: j['simulada'] as bool,
        mensaje: j['mensaje'] as String,
      );

  final String referencia;
  final String instrumentoNombre;
  final String entidadNombre;
  final String url;
  final int? monto;
  final bool simulada;
  final String mensaje;
}

/// Un evento de seguridad de la propia cuenta (la bitácora que ve la persona).
class EventoActividad {
  const EventoActividad({required this.tipo, required this.fecha});

  factory EventoActividad.fromJson(Map<String, dynamic> j) => EventoActividad(
        tipo: j['tipo'] as String,
        fecha: DateTime.parse(j['fecha'] as String).toLocal(),
      );

  final String tipo;
  final DateTime fecha;

  static const _etiquetas = {
    'login_exitoso': 'Inicio de sesión',
    'login_fallido': 'Intento de inicio de sesión fallido',
    'login_rechazado_por_bloqueo': 'Intento rechazado: cuenta bloqueada temporalmente',
    'ip_bloqueada': 'Demasiados intentos desde tu conexión',
    'refresco_reutilizado': 'Sesión cerrada por seguridad',
    'sesiones_cerradas': 'Sesiones cerradas',
    'reautenticacion_fallida': 'Contraseña de confirmación incorrecta',
    'contrasena_cambiada': 'Contraseña cambiada',
    'email_cambiado': 'Correo cambiado',
    'cuenta_eliminada': 'Cuenta eliminada',
    'recuperacion_solicitada': 'Recuperación de contraseña solicitada',
    'recuperacion_completada': 'Contraseña recuperada',
    'recuperacion_fallida': 'Recuperación de contraseña fallida',
    'derivacion_inversion': 'Fuiste a una entidad de inversión (simulada)',
  };

  /// Texto para la persona; si el tipo es nuevo y no está en la lista, lo muestra tal cual.
  String get etiqueta => _etiquetas[tipo] ?? tipo;
}

/// Resumen de lo que la app guarda de la persona (derecho de acceso, Ley 21.719).
class DatosCuenta {
  const DatosCuenta({
    required this.email,
    required this.creadoEn,
    required this.movimientos,
    required this.confirmaciones,
    required this.consentimientos,
    required this.perfilRiesgo,
  });

  factory DatosCuenta.fromJson(Map<String, dynamic> j) => DatosCuenta(
        email: j['email'] as String,
        creadoEn: DateTime.parse(j['creado_en'] as String).toLocal(),
        movimientos: (j['movimientos'] as List<dynamic>).length,
        confirmaciones: (j['confirmaciones'] as List<dynamic>).length,
        consentimientos: (j['consentimientos'] as List<dynamic>).length,
        perfilRiesgo: j['perfil_riesgo'] as String?,
      );

  final String email;
  final DateTime creadoEn;
  final int movimientos;
  final int confirmaciones;
  final int consentimientos;
  final String? perfilRiesgo;
}
