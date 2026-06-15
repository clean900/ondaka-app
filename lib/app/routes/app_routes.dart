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
  static const homeGestor = '/home-gestor';

  // === Visitantes (condómino) ===
  static const criarPreAprovacao = '/pre-aprovacoes/criar';
  static const minhasPreAprovacoes = '/pre-aprovacoes/minhas';
  static const historicoVisitas = '/pre-aprovacoes/historico';

  // === Prestadores (condómino) ===
  static const prestadores = '/prestadores';

  // === Portaria (funcionário) ===
  static const validarOtp = '/portaria/validar-otp';
  static const dentroAgora = '/portaria/dentro-agora';

  static const marketplace = '/marketplace';

  // Comissão de moradores (F-03)
  static const despesasComissao = '/despesas-comissao';
}
