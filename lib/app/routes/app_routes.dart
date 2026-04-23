/// Constantes das rotas da app ONDAKA.
/// Use estas constantes em vez de strings literais em todo o código.
///
/// Exemplo: Get.toNamed(AppRoutes.login)
abstract class AppRoutes {
  AppRoutes._();

  // === Entry ===
  static const splash = '/';

  // === Auth ===
  static const login = '/login';
  static const twoFactor = '/login/2fa';

  // === App principal (multi-perfil) ===
  static const home = '/home';

  // Futuramente, à medida que implementarmos:
  // static const visitors = '/visitors';
  // static const tickets = '/tickets';
  // static const assemblies = '/assemblies';
  // ...
}
