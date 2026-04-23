import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

/// Widget raiz da aplicação ONDAKA.
class OndakaApp extends StatelessWidget {
  const OndakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ONDAKA',
      debugShowCheckedModeBanner: false,

      // Tema dark ONDAKA
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      // Rotas GetX
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,

      // Localização (pt-AO)
      locale: const Locale('pt', 'AO'),
      fallbackLocale: const Locale('pt', 'PT'),

      // Transições suaves entre rotas
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
