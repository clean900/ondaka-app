/// Configuração central da API ONDAKA.
///
/// Altera aqui as URLs e timeouts — o resto da app puxa destas constantes.
class ApiConfig {
  ApiConfig._();

  /// URL base da API em produção.
  /// No futuro podemos ter um [ApiEnv] (dev/staging/prod) para trocar URLs.
  static const String baseUrl = 'https://ondaka.ao/api';

  /// Timeout para estabelecer conexão (handshake TCP+TLS).
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Timeout para receber dados depois de conexão estabelecida.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Timeout para enviar body (upload).
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Headers padrão enviados em todos os requests.
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
