import 'package:flutter/material.dart';
import 'sem_acesso_view.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../avisos/views/meus_avisos_view.dart';
import '../../chatbot/views/chatbot_bottomsheet.dart';
import '../../sos/views/sos_view.dart';
import '../../home/views/home_view.dart';
import '../../pre_aprovacoes/views/visitas_shell_view.dart';
import '../controllers/main_shell_controller.dart';
import 'mais_view.dart';
import '../../notificacoes/widgets/notificacao_sino.dart';

/// Shell principal da app — Scaffold com bottom navigation.
/// Substitui o HomeView como rota principal pós-login para condómino.
class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView>
    with WidgetsBindingObserver {
  late final MainShellController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MainShellController());
    WidgetsBinding.instance.addObserver(this);
    // Refresh dados do user ao abrir a app (corrige Bug B-USER-01)
    AuthService.to.fetchUser();
    // Garante que os acessos do familiar estao carregados ao abrir o shell
    AuthService.to.carregarRole();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh quando app volta do background (corrige Bug B-USER-01)
    if (state == AppLifecycleState.resumed) {
      AuthService.to.fetchUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const HomeView(),
      const GateAcesso(acesso: 'visitas', child: VisitasShellView()),
      const SosView(),
      const GateAcesso(acesso: 'avisos', child: MeusAvisosView()),
      const MaisView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          Obx(
            () => IndexedStack(
              index: controller.tabIndex.value,
              children: tabs,
            ),
          ),
          // === Sino de notificações flutuante ===
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: const NotificacaoSino(),
          ),
        ],
      ),
      floatingActionButton: _ChatbotFab(
        onPressed: () async {
          final user = await StorageService.to.getUser();
          if (!context.mounted) return;
          ChatbotBottomsheet.abrir(context, userName: user['name']);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.tabIndex.value,
          onDestinationSelected: controller.mudarTab,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.cyan.withValues(alpha: 0.18),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
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
            // SOS ao centro — destacado (emergencia)
            NavigationDestination(
              icon: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
                child: const Icon(Icons.emergency_outlined, color: Colors.white, size: 24),
              ),
              selectedIcon: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger,
                  boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)],
                ),
                child: const Icon(Icons.emergency, color: Colors.white, size: 24),
              ),
              label: 'SOS',
            ),
            NavigationDestination(
              icon: controller.avisosNaoLidos.value > 0
                  ? Badge(
                      label: Text('${controller.avisosNaoLidos.value}'),
                      child: const Icon(Icons.campaign_outlined),
                    )
                  : const Icon(Icons.campaign_outlined),
              selectedIcon: controller.avisosNaoLidos.value > 0
                  ? Badge(
                      label: Text('${controller.avisosNaoLidos.value}'),
                      child: const Icon(Icons.campaign, color: AppColors.cyan),
                    )
                  : const Icon(Icons.campaign, color: AppColors.cyan),
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

/// FAB do Chatbot — gradient cyan→purple, ícone smart_toy.
/// FAB SOS — canto inferior esquerdo, vermelho com pulse subtil para chamar atenção.
class _SosFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _SosFab({required this.onPressed});

  @override
  State<_SosFab> createState() => _SosFabState();
}

class _SosFabState extends State<_SosFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final scale = 1.0 + 0.04 * _pulse.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: FloatingActionButton.extended(
        heroTag: 'sos_fab',
        onPressed: widget.onPressed,
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.emergency_outlined, size: 22),
        label: const Text(
          'SOS',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
      ),
    );
  }
}

class _ChatbotFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _ChatbotFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
