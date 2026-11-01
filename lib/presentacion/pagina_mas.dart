import 'package:flutter/material.dart';

import 'pagina_aprender.dart';
import 'pagina_banco.dart';
import 'pagina_cuenta.dart';
import 'pagina_invertir.dart';

/// Pestaña "Más": reúne Invertir, Banco, Aprender y Mi cuenta para que la barra inferior no se llene.
/// Se cambia de vista dentro de la misma pestaña (sin rutas nuevas), así los
/// controladores de la zona autenticada siguen disponibles.
class PaginaMas extends StatefulWidget {
  const PaginaMas({super.key});

  @override
  State<PaginaMas> createState() => _PaginaMasState();
}

enum _Vista { menu, invertir, banco, aprender, cuenta }

class _PaginaMasState extends State<PaginaMas> {
  _Vista _vista = _Vista.menu;

  @override
  Widget build(BuildContext context) {
    if (_vista == _Vista.menu) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Invertir'),
              subtitle: const Text('Opciones según tu perfil y paso a la entidad socia'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _vista = _Vista.invertir),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Banco'),
              subtitle: const Text('Conecta tu banco (solo lectura) e importa abonos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _vista = _Vista.banco),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Aprender'),
              subtitle: const Text('Lecciones cortas de educación financiera'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _vista = _Vista.aprender),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Mi cuenta'),
              subtitle: const Text('Tus datos, tu actividad, contraseña y eliminar cuenta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _vista = _Vista.cuenta),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _vista = _Vista.menu),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
          ),
        ),
        Expanded(
          child: switch (_vista) {
            _Vista.invertir => const PaginaInvertir(),
            _Vista.banco => const PaginaBanco(),
            _Vista.cuenta => const PaginaCuenta(),
            _ => const PaginaAprender(),
          },
        ),
      ],
    );
  }
}
