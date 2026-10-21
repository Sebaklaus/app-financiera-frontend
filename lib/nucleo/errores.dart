/// Error de la API o de la conexión, con un mensaje listo para mostrar.
/// [estado] es el código HTTP; es null cuando no hubo respuesta (sin conexión).
class ErrorApi implements Exception {
  const ErrorApi(this.estado, this.mensaje);

  final int? estado;
  final String mensaje;

  bool get esSinConexion => estado == null;

  @override
  String toString() => mensaje;
}
