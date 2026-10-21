import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/modelos.dart';
import '../estado/finanzas_controlador.dart';
import '../nucleo/formato.dart';
import 'widgets/aviso_error.dart';

/// Hoja para registrar un gasto en una categoría.
class HojaGasto extends StatefulWidget {
  const HojaGasto({super.key});

  @override
  State<HojaGasto> createState() => _HojaGastoState();
}

class _HojaGastoState extends State<HojaGasto> {
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();
  Categoria _categoria = Categoria.necesidades;
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
    final navegador = Navigator.of(context);
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final texto = _descripcion.text.trim();
    final ok = await finanzas.registrarGasto(
        monto, _categoria, texto.isEmpty ? 'Gasto' : texto);
    if (!mounted) return;
    if (ok) {
      navegador.pop();
    } else {
      setState(() {
        _ocupado = false;
        _error = finanzas.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Registrar gasto',
              style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
          DropdownButtonFormField<Categoria>(
            initialValue: _categoria,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [
              for (final c in Categoria.values)
                DropdownMenuItem(value: c, child: Text(c.etiqueta)),
            ],
            onChanged: (v) => setState(() => _categoria = v ?? _categoria),
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
                : const Text('Registrar gasto'),
          ),
        ],
      ),
    );
  }
}
