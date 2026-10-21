# App Financiera – cliente Flutter (etapas 1 a 3)

## Cómo ejecutar
Con uvicorn corriendo en el backend (y `http://localhost:5600` en `CORS_ORIGINS`):

    flutter pub get
    flutter analyze
    flutter test
    flutter run -d edge --web-port 5600 --dart-define=API_URL=http://127.0.0.1:8000

## Flujo de la app
1. Login / registro.
2. Consentimientos por separado + perfil de riesgo (si faltan los obligatorios).
3. Resumen por categoría, con botones Ingreso y Gasto.
4. Al registrar un ingreso se muestra el reparto 50/25/15/10; el 25 % y el 15 %
   quedan pendientes en la pestaña Confirmar.
5. Movimientos, con opción de eliminar.
6. Banco: conexión de prueba con Fintoc (solo lectura), cuentas, movimientos del
   banco e importación de abonos como ingresos.
7. Aprender: 4 lecciones educativas básicas.

## Estructura
    lib/dominio/       modelos (sin Flutter ni HTTP)
    lib/nucleo/        configuración, tema, formato de pesos, errores
    lib/datos/         cliente HTTP, almacén seguro, repositorios (interfaz + API)
    lib/estado/        controladores (ChangeNotifier)
    lib/presentacion/  pantallas, hojas y widgets
    test/              pruebas
