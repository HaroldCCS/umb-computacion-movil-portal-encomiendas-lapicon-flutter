/// Configuración de entorno. Se puede cambiar al ejecutar:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
abstract final class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lapticon-backend.onrender.com',
  );

  /// El backend está en el plan gratuito de Render: la primera petición
  /// después de un rato inactivo puede tardar hasta un minuto.
  static const Duration requestTimeout = Duration(seconds: 75);

  /// Si una petición tarda más que esto, se muestra el aviso
  /// "Despertando el servidor…".
  static const Duration slowRequestThreshold = Duration(seconds: 5);
}
