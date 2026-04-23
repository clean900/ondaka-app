import 'package:get/get.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/home/views/home_view.dart';
import '../../features/splash/views/splash_view.dart';
import 'app_routes.dart';

/// Mapeamento rota → página para o GetX.
/// Quando adicionares nova feature, regista aqui a sua GetPage.
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
    // Próximas rotas:
    // GetPage(name: AppRoutes.twoFactor, page: () => const TwoFactorView()),
  ];
}
