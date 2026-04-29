import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../avisos/views/meus_avisos_view.dart';
import '../../home/views/home_view.dart';
import '../../pre_aprovacoes/views/minhas_pre_aprovacoes_view.dart';
import '../controllers/main_shell_controller.dart';

/// Shell principal da app — Scaffold com bottom navigation.
/// Substitui o HomeView como rota principal pós-login para condómino.
class MainShellView extends StatelessWidget {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainShellController());

    final tabs = [
      const HomeView(),
      const MinhasPreAprovacoesView(),
      const MeusAvisosView(),
      const _MaisPlaceholderTab(),
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

/// Placeholder temporário para a tab "Mais".
/// Será substituída por uma lista de itens secundários no Passo 4.
class _MaisPlaceholderTab extends StatelessWidget {
  const _MaisPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Mais')),
      body: const Center(
        child: Text(
          'Em construção...',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
