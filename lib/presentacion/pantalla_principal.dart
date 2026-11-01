import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/banco_controlador.dart';
import '../estado/finanzas_controlador.dart';
import '../estado/metas_controlador.dart';
import '../estado/sesion_controlador.dart';
import 'pagina_confirmaciones.dart';
import 'pagina_inicio.dart';
import 'pagina_mas.dart';
import 'pagina_metas.dart';
import 'pagina_movimientos.dart';

/// Contenedor con la barra inferior: Resumen, Confirmar, Movimientos, Metas y Más (Banco y Aprender).
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _pestana = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FinanzasControlador>().cargar();
      context.read<BancoControlador>().cargar();
      context.read<MetasControlador>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanzasControlador>();
    final sesion = context.watch<SesionControlador>();
    final pendientes = f.pendientes.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Financiera'),
        actions: [
          if (f.cargando || f.ocupado)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: f.cargar,
          ),
          PopupMenuButton<String>(
            tooltip: sesion.email ?? 'Cuenta',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (v) {
              if (v == 'salir') context.read<SesionControlador>().cerrarSesion();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(sesion.email ?? 'Tu cuenta'),
              ),
              const PopupMenuItem<String>(
                value: 'salir',
                child: Text('Cerrar sesión'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _pestana,
        children: [
          PaginaInicio(irAConfirmaciones: () => setState(() => _pestana = 1)),
          const PaginaConfirmaciones(),
          const PaginaMovimientos(),
          const PaginaMetas(),
          const PaginaMas(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendientes > 0,
              label: Text('$pendientes'),
              child: const Icon(Icons.task_alt_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendientes > 0,
              label: Text('$pendientes'),
              child: const Icon(Icons.task_alt),
            ),
            label: 'Confirmar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Movimientos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Metas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
