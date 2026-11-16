import '../../core/services/storage_service.dart';
import 'app_routes.dart';

/// Decide qual é a Home apropriada para o user, baseado na sua role.
///
/// Uso:
/// ```dart
/// final route = await HomeRouter.rotaPorRole();
/// Get.offAllNamed(route);
/// ```
class HomeRouter {
  HomeRouter._();

  /// Lê a role guardada e devolve a rota da Home apropriada.
  static Future<String> rotaPorRole() async {
    final user = await StorageService.to.getUser();
    final role = user['role'];

    return _mapearRole(role);
  }

  /// Mapeia uma role para a rota correspondente.
  /// Exposta para casos onde já temos a role em mão (ex: depois de login).
  static String rotaParaRole(String? role) => _mapearRole(role);

  static String _mapearRole(String? role) {
    switch (role) {
      case 'funcionario':
      case 'guarda':
        return AppRoutes.homeGuarda;

      case 'administrador-condominio':
      case 'gestor':
      case 'admin-empresa':
      case 'super-admin':
        return AppRoutes.homeGestor;

      // Só chega aqui quem TEM APENAS a role de afiliado (ver
      // AuthService._rolePrincipal): não é condómino nem gere nada, por isso
      // a casa dele é o portal do afiliado. Um gestor que também seja
      // afiliado continua a entrar na gestão.
      case 'afiliado':
        return AppRoutes.afiliados;

      case 'condomino':
      case 'familiar':
      case null:
      default:
        return AppRoutes.home;
    }
  }
}
