import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/modelos.dart';
import '../estado/banco_controlador.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'widgets/aviso_error.dart';
import 'widgets/contenido_centrado.dart';

/// Conexión de un banco (modo prueba) y recorrido de los datos.
class PaginaBanco extends StatefulWidget {
  const PaginaBanco({super.key});

  @override
  State<PaginaBanco> createState() => _PaginaBancoState();
}

class _PaginaBancoState extends State<PaginaBanco> {
  final _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _conectar(BancoControlador b) async {
    final ok = await b.conectar(_token.text);
    if (ok) _token.clear();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BancoControlador>();
    final tema = Theme.of(context);
    return RefreshIndicator(
      onRefresh: b.cargar,
      child: ContenidoCentrado(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tu banco',
                style: tema.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const _RecorridoDatos(),
            const SizedBox(height: 12),
            if (b.error != null) AvisoError(b.error!),
            if (b.aviso != null) _AvisoOk(b.aviso!),
            if (b.cargando && !b.conectado)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!b.conectado)
              _FormularioConexion(
                controlador: _token,
                ocupado: b.ocupado,
                alConectar: () => _conectar(b),
              )
            else ...[
              for (final c in b.cuentas!) _TarjetaCuenta(c, b),
              if (b.seleccionada != null) _MovimientosBanco(b),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: b.ocupado ? null : b.desconectar,
                icon: const Icon(Icons.link_off),
                label: const Text('Desconectar banco'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecorridoDatos extends StatelessWidget {
  const _RecorridoDatos();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      color: tema.colorScheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Así viajan tus datos',
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('Banco → Fintoc → nuestra API → base de datos → reparto 50/25/15/10.'),
            SizedBox(height: 6),
            Text(
                'Solo lectura: la app no puede mover dinero ni ve tus credenciales '
                'bancarias. El enlace se guarda cifrado en el servidor.'),
          ],
        ),
      ),
    );
  }
}

class _AvisoOk extends StatelessWidget {
  const _AvisoOk(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colores.inversion.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colores.inversion.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colores.inversion, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _FormularioConexion extends StatelessWidget {
  const _FormularioConexion({
    required this.controlador,
    required this.ocupado,
    required this.alConectar,
  });

  final TextEditingController controlador;
  final bool ocupado;
  final VoidCallback alConectar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
            'Modo prueba (sandbox): pega el link_token del enlace de prueba. '
            'En producción lo entrega el widget de Fintoc al autorizar tu banco.'),
        const SizedBox(height: 12),
        TextField(
          controller: controlador,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => alConectar(),
          decoration: const InputDecoration(
            labelText: 'link_token de prueba',
            hintText: 'link_..._token_...',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: ocupado ? null : alConectar,
          child: ocupado
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Conectar banco'),
        ),
      ],
    );
  }
}

class _TarjetaCuenta extends StatelessWidget {
  const _TarjetaCuenta(this.cuenta, this.b);

  final CuentaBancaria cuenta;
  final BancoControlador b;

  @override
  Widget build(BuildContext context) {
    final elegida = b.seleccionada?.id == cuenta.id;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: elegida
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: const Icon(Icons.account_balance_outlined),
        title: Text('${cuenta.nombre} ${cuenta.numeroEnmascarado}'),
        subtitle: Text(
            cuenta.saldo == null ? 'Saldo no informado' : 'Saldo ${clp(cuenta.saldo!)}'),
        trailing: TextButton(
          onPressed: b.ocupado ? null : () => b.verMovimientos(cuenta),
          child: const Text('Ver movimientos'),
        ),
      ),
    );
  }
}

class _MovimientosBanco extends StatelessWidget {
  const _MovimientosBanco(this.b);

  final BancoControlador b;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lista = b.movimientos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text('Movimientos que informa el banco',
            style: tema.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (lista.isEmpty) const Text('Esta cuenta no tiene movimientos.'),
        for (final m in lista.take(30))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(m.descripcion),
            subtitle: Text(fechaCorta(m.fecha)),
            trailing: Text(
              clp(m.monto),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: m.esAbono ? Colores.inversion : Colores.error,
              ),
            ),
          ),
        if (lista.length > 30)
          Text('Mostrando 30 de ${lista.length} movimientos.',
              style: tema.textTheme.bodySmall),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: b.ocupado || lista.isEmpty ? null : b.importar,
          icon: const Icon(Icons.download),
          label: const Text('Importar abonos como ingresos'),
        ),
        const SizedBox(height: 4),
        Text(
            'Solo los abonos se importan; los cargos se omiten. Cada abono se reparte '
            '50/25/15/10 y el 25 % y el 15 % esperan tu confirmación.',
            style: tema.textTheme.bodySmall),
      ],
    );
  }
}
