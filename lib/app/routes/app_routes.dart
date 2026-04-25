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

  // === Home (por role) ===
  static const home = '/home';
  static const homeGuarda = '/home-guarda';

  // === Visitantes (condómino) ===
  static const criarPreAprovacao = '/pre-aprovacoes/criar';
  static const historicoVisitas = '/pre-aprovacoes/historico';

  // === Portaria (funcionário) ===
  static const validarOtp = '/portaria/validar-otp';
  static const dentroAgora = '/portaria/dentro-agora';
}
