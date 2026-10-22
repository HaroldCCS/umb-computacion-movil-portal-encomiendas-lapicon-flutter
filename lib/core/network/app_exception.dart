/// Errores propios de la app. Las pantallas solo muestran [message].
/// (No es `sealed` porque `AuthException` vive en la capa de servicios.)
abstract class AppException implements Exception {
  const AppException(this.message);

  /// Mensaje en lenguaje humano, listo para mostrar.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// El servidor respondió con un código de error (4xx / 5xx).
class ApiException extends AppException {
  const ApiException(this.statusCode, super.message);

  final int statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isBusinessRule => statusCode == 400 || statusCode == 409;

  /// Mensaje por defecto cuando el backend no envía uno.
  static String defaultMessage(int statusCode) {
    if (statusCode == 400) return 'Revisa los datos e intenta de nuevo.';
    if (statusCode == 401) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    if (statusCode == 403) return 'No tienes permiso para hacer esto.';
    if (statusCode == 404) return 'No encontramos lo que buscas.';
    if (statusCode >= 500) {
      return 'Algo falló en el servidor. Intenta de nuevo en un momento.';
    }
    return 'No se pudo completar la solicitud ($statusCode).';
  }
}

/// No hubo respuesta: sin internet, DNS o tiempo de espera agotado.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No pudimos conectarnos. Revisa tu conexión a internet.',
  ]);
}

/// El usuario no tiene sesión (no hay token para enviar).
class NotAuthenticatedException extends AppException {
  const NotAuthenticatedException([
    super.message = 'Inicia sesión para continuar.',
  ]);
}
