import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/sesion_controlador.dart';
import '../nucleo/tema.dart';
import 'pantalla_recuperacion.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _email = TextEditingController();
  final _clave = TextEditingController();
  bool _registro = false;
  bool _verClave = false;

  @override
  void dispose() {
    _email.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final sesion = context.read<SesionControlador>();
    if (_clave.text.isEmpty) return;
    if (_registro) {
      await sesion.registrar(_email.text, _clave.text);
    } else {
      await sesion.iniciarSesion(_email.text, _clave.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionControlador>();
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.savings_outlined,
                      size: 56, color: tema.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('HelpFinance',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Cada ingreso, repartido 50/25/15/10.\n'
                    'Tú decides; tu dinero nunca pasa por la app.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => sesion.limpiarError(),
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _clave,
                    obscureText: !_verClave,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _enviar(),
                    onChanged: (_) => sesion.limpiarError(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                        icon: Icon(_verClave
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _verClave = !_verClave),
                      ),
                    ),
                  ),
                  if (sesion.error != null) ...[
                    const SizedBox(height: 14),
                    _Aviso(texto: sesion.error!),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: sesion.ocupado ? null : _enviar,
                    child: sesion.ocupado
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(_registro ? 'Crear cuenta' : 'Entrar'),
                  ),
                  const SizedBox(height: 8),
                  if (!_registro)
                    TextButton(
                      onPressed: sesion.ocupado
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PantallaRecuperacion(
                                  emailInicial: _email.text))),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  TextButton(
                    onPressed: sesion.ocupado
                        ? null
                        : () => setState(() {
                              _registro = !_registro;
                              sesion.limpiarError();
                            }),
                    child: Text(_registro
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Regístrate'),
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

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
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
