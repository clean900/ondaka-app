import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/routes/home_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';

/// Splash screen inicial.
///
/// Responsável por decidir para onde ir depois do arranque:
/// - Se houver token guardado e válido → home apropriada à role
/// - Caso contrário → /login
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _decideInitialRoute();
  }

  Future<void> _decideInitialRoute() async {
    // Mínimo de 1.5s para o splash não ser um "flash" (UX).
    final minimumDelay = Future.delayed(const Duration(milliseconds: 1500));
    final authCheck = _checkAuth();

    final results = await Future.wait([minimumDelay, authCheck]);
    final isAuthenticated = results[1] as bool;

    if (!mounted) return;

    if (isAuthenticated) {
      final homeRoute = await HomeRouter.rotaPorRole();
      Get.offAllNamed(homeRoute);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<bool> _checkAuth() async {
    final hasToken = await StorageService.to.isLoggedIn();
    if (!hasToken) return false;

    final user = await AuthService.to.fetchUser();
    if (user == null) {
      await StorageService.to.clearAll();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.5),
                    blurRadius: 60,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'O',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF001218),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.brandGradientHorizontal.createShader(bounds),
              child: const Text(
                'ONDAKA',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gestão de Condomínios',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyanSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
