import 'package:flutter/material.dart';
import '../../pre_aprovacoes/repositories/pre_aprovacao_repository.dart';
import '../../pre_aprovacoes/views/historico_visitas_view.dart';
import 'package:get/get.dart';
import '../../tickets/views/meus_tickets_view.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';

/// Ecrã Home placeholder.
///
/// Mostra dados do user logado e permite logout.
/// Será substituído por dashboard multi-perfil (condómino/admin/guarda/etc.)
/// nas próximas iterações.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONDAKA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: StorageService.to.getUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // === Boas-vindas ===
                Text(
                  'Olá, ${user['name'] ?? 'Utilizador'}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  user['role'] ?? 'sem role',
                  style: const TextStyle(
                    color: AppColors.cyanSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // === Acções rápidas ===
                _accaoRapida(
                  icon: Icons.person_add_alt_1,
                  label: 'Pré-aprovar visitante',
                  subtitle: 'Autorizar uma visita com antecedência',
                  onTap: () => Get.toNamed(AppRoutes.criarPreAprovacao),
                ),
                const SizedBox(height: 12),
                _accaoRapida(
                  icon: Icons.list_alt,
                  label: 'Minhas pré-aprovações',
                  subtitle: 'Ver e cancelar pré-aprovações criadas',
                  onTap: () => Get.toNamed(AppRoutes.minhasPreAprovacoes),
                ),
                const SizedBox(height: 12),
                _accaoRapida(
                  icon: Icons.history,
                  label: 'Histórico de visitas',
                  subtitle: 'Ver todas as visitas das suas fracções',
                  onTap: () => Get.to(() => HistoricoVisitasView(fetch: PreAprovacaoRepository().historicoVisitas)),
                ),
                const SizedBox(height: 12),
                _accaoRapida(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Tickets',
                  subtitle: 'Reportar problemas e ver os meus pedidos',
                  onTap: () => Get.to(() => const MeusTicketsView()),
                ),
                const SizedBox(height: 24),

                // === Card info ===
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sessão autenticada',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textFaint,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Email', user['email'] ?? '-'),
                        _infoRow('User ID', user['id'] ?? '-'),
                        _infoRow('Empresa ID', user['empresa_gestora_id'] ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // === Notas ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.06),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.cyanSoft, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Em construção',
                            style: TextStyle(
                              color: AppColors.cyanSoft,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'O dashboard completo será implementado em iterações seguintes '
                        'com navegação condicional por role (condómino, admin, guarda, etc.).',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _accaoRapida({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.25),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF001218), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF001218),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF001218),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'Terminar sessão',
      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      middleText: 'Tens a certeza que queres sair?',
      middleTextStyle:
          const TextStyle(color: AppColors.textMuted, fontSize: 13),
      backgroundColor: AppColors.surface,
      radius: 14,
      textCancel: 'Cancelar',
      textConfirm: 'Sair',
      confirmTextColor: AppColors.bgDark,
      buttonColor: AppColors.cyan,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirm == true) {
      await AuthService.to.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
