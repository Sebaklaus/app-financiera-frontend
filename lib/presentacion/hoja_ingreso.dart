import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/modelos.dart';
import '../estado/finanzas_controlador.dart';
import '../nucleo/formato.dart';
import 'widgets/aviso_error.dart';
import 'widgets/barra_reparto.dart';

/// Hoja para registrar un ingreso. Al terminar muestra cómo se repartió.
class HojaIngreso extends StatefulWidget {
  const HojaIngreso({super.key, required this.alVerConfirmaciones});

  final VoidCallback alVerConfirmaciones;

  @override
  State<HojaIngreso> createState() => _HojaIngresoState();
}

class _HojaIngresoState extends State<HojaIngreso> {
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();
  IngresoRegistrado? _resultado;
  String? _error;
  bool _ocupado = false;

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final monto = parseMonto(_monto.text);
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Escribe un monto mayor a cero.');
      return;
    }
    final finanzas = context.read<FinanzasControlador>();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final texto = _descripcion.text.trim();
    final r = await finanzas.registrarIngreso(monto, texto.isEmpty ? 'Ingreso' : texto);
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _resultado = r;
      _error = r == null ? finanzas.error : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final r = _resultado;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: r == null ? _formulario(tema) : _exito(tema, r),
    );
  }

  Widget _formulario(ThemeData tema) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Registrar ingreso',
            style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('La app propone el reparto 50/25/15/10; tú decides.'),
        const SizedBox(height: 16),
        TextField(
          controller: _monto,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monto (pesos)',
            prefixText: '\$ ',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descripcion,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _registrar(),
          decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AvisoError(_error!),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _ocupado ? null : _registrar,
          child: _ocupado
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Registrar ingreso'),
        ),
      ],
    );
  }

  Widget _exito(ThemeData tema, IngresoRegistrado r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ingreso de ${clp(r.monto)} registrado',
            style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
            'Así se reparte. El 25 % y el 15 % esperan tu decisión: no se aparta nada sin tu confirmación.'),
        const SizedBox(height: 16),
        BarraReparto(reparto: r.reparto),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.alVerConfirmaciones,
          child: const Text('Decidir ahora'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Después'),
        ),
      ],
    );
  }
}
