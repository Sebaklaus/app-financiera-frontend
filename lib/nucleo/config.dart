/// Configuración del cliente. La URL de la API se cambia al compilar, sin tocar
/// el código:  flutter run -d chrome --dart-define=API_URL=https://mi-api.run.app
class Config {
  static const String urlApi = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
