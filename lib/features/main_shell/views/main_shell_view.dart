import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../avisos/views/meus_avisos_view.dart';
import '../../home/views/home_view.dart';
import '../../pre_aprovacoes/views/visitas_shell_view.dart';
import '../controllers/main_shell_controller.dart';
import 'mais_view.dart';

/// Shell principal da app — Scaffold com bottom navigation.
/// Substitui o HomeView como rota principal pós-login para condómino.
class MainShellView extends StatelessWidget {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainShellController());

    final tabs = [
      const HomeView(),
      const VisitasShellView(),
      const MeusAvisosView(),
      const MaisView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Obx(
        () => IndexedStack(
          index: controller.tabIndex.value,
          children: tabs,
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.tabIndex.value,
          onDestinationSelected: controller.mudarTab,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.cyan.withValues(alpha: 0.18),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.cyan),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: AppColors.cyan),
              label: 'Visitas',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications, color: AppColors.cyan),
              label: 'Avisos',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_outlined),
              selectedIcon: Icon(Icons.menu, color: AppColors.cyan),
              label: 'Mais',
            ),
          ],
        ),
      ),
    );
  }
}
