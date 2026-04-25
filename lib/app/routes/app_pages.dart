import 'package:get/get.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/home/views/home_view.dart';
import '../../features/portaria/views/dentro_agora_view.dart';
import '../../features/portaria/views/home_guarda_view.dart';
import '../../features/portaria/views/validar_otp_view.dart';
import '../../features/pre_aprovacoes/views/criar_pre_aprovacao_view.dart';
import '../../features/pre_aprovacoes/views/historico_visitas_view.dart';
import '../../features/splash/views/splash_view.dart';
import 'app_routes.dart';

/// Mapeamento rota → página para o GetX.
abstract class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
    ),
    GetPage(
      name: AppRoutes.homeGuarda,
      page: () => const HomeGuardaView(),
    ),
    GetPage(
      name: AppRoutes.criarPreAprovacao,
      page: () => const CriarPreAprovacaoView(),
    ),
    GetPage(
      name: AppRoutes.historicoVisitas,
      page: () => const HistoricoVisitasView(),
    ),
    GetPage(
      name: AppRoutes.validarOtp,
      page: () => const ValidarOtpView(),
    ),
    GetPage(
      name: AppRoutes.dentroAgora,
      page: () => const DentroAgoraView(),
    ),
  ];
}
