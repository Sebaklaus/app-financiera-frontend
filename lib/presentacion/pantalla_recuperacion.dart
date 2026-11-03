import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/sesion_controlador.dart';
import '../nucleo/tema.dart';

/// Recuperar la contraseña en dos pasos: pedir el código y usarlo.
/// En desarrollo el código sale en la terminal del servidor (CORREO_MODO=consola).
class PantallaRecuperacion extends StatefulWidget {
  const PantallaRecuperacion({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<PantallaRecuperacion> createState() => _PantallaRecuperacionState();
}

class _PantallaRecuperacionState extends State<PantallaRecuperacion> {
  late final TextEditingController _email =
      TextEditingController(text: widget.emailInicial);
  final _codigo = TextEditingController();
  final _nueva = TextEditingController();
  bool _paso2 = false;
  bool _ocupado = false;
  bool _verClave = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _nueva.dispose();
    super.dispose();
  }

  Future<void> _pedir() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final error =
        await context.read<SesionControlador>().solicitarRecuperacion(_email.text);
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _error = error;
      if (error == null) _paso2 = true;
    });
  }

  Future<void> _restablecer() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final error = await context
        .read<SesionControlador>()
        .restablecerContrasena(_codigo.text, _nueva.text);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Listo: ya puedes entrar con tu nueva contraseña.')));
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _ocupado = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _paso2
                        ? 'Si el correo tiene una cuenta, te enviamos un código. '
                            'Pégalo aquí y elige tu nueva contraseña. Dura 30 minutos '
                            'y sirve una sola vez.'
                        : 'Escribe el correo de tu cuenta y te enviaremos un código.',
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    enabled: !_paso2,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  if (_paso2) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _codigo,
                      decoration: const InputDecoration(
                        labelText: 'Código recibido',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nueva,
                      obscureText: !_verClave,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        helperText: 'Mínimo 8 caracteres, una letra y un número',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                          icon: Icon(_verClave
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _verClave = !_verClave),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Colores.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _ocupado ? null : (_paso2 ? _restablecer : _pedir),
                    child: _ocupado
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Text(_paso2 ? 'Cambiar contraseña' : 'Enviar código'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
