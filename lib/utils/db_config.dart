/// Configuración central de la Base de Datos y la API REST.
/// Cambia los valores aquí para conectar a tu propio servidor o base de datos.
class DbConfig {
  /// URL base de tu API REST.
  /// - Para emulador de Android local usa: 'http://10.0.2.2:3000/api'
  /// - Para emulador de iOS local usa: 'http://localhost:3000/api'
  /// - Para producción/servidor remoto usa la IP pública o dominio: 'https://mi-api-inventario.com/api'
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  /// Nombre de la base de datos remota que montaste (Ej: 'inventario_db')
  /// Esto sirve como identificador y referencia para las solicitudes o configuraciones de tu API.
  static const String databaseName = 'inventario_multiplataforma';

  /// Puerto de conexión a tu API (si aplica, Ej: 3000, 8080)
  static const int apiPort = 3000;

  /// Tiempo de espera máximo para peticiones de red (en segundos)
  static const int connectionTimeoutSeconds = 10;
}
