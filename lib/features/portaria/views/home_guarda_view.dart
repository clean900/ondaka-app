import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pre_aprovacoes/views/historico_visitas_view.dart';
import '../repositories/portaria_repository.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';

/// Home do guarda (funcionário de portaria).
///
/// Acesso às operações principais:
/// - Validar OTP introduzido pelo visitante
/// - Ver quem está dentro agora
///
/// Futuramente: scan de QR, entrada manual, histórico.
class HomeGuardaView extends StatelessWidget {
  const HomeGuardaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Portaria'),
        backgroundColor: AppColors.bgDark,
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
                const SizedBox(height: 8),

                // Boas-vindas
                Text(
                  'Olá, ${user['name'] ?? 'Guarda'}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Portaria — ONDAKA',
                  style: TextStyle(
                    color: AppColors.cyanSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Botão principal — validar OTP
                _accaoGrande(
                  icon: Icons.password,
                  label: 'Validar código',
                  subtitle: 'Visitante apresentou OTP de 6 dígitos',
                  onTap: () => Get.toNamed(AppRoutes.validarOtp),
                  primary: true,
                ),
                const SizedBox(height: 14),

                // Botão secundário — dentro agora
                _accaoGrande(
                  icon: Icons.group,
                  label: 'Quem está dentro',
                  subtitle: 'Ver visitantes actualmente no condomínio',
                  onTap: () => Get.toNamed(AppRoutes.dentroAgora),
                  primary: false,
                ),
                const SizedBox(height: 14),
                _accaoGrande(
                  icon: Icons.history,
                  label: 'Histórico de visitas',
                  subtitle: 'Ver todas as visitas registadas',
                  onTap: () => Get.to(() => HistoricoVisitasView(
                        fetch: PortariaRepository().historicoVisitas,
                        tituloAppBar: 'Histórico do condomínio',
                      )),
                  primary: false,
                ),
                const SizedBox(height: 32),

                // Info card
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
                        'Scanner de QR e entrada manual serão adicionados em '
                        'próximas iterações.',
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

  Widget _accaoGrande({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: primary ? AppColors.brandGradient : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.25),
                    blurRadius: 25,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary
                    ? Colors.black.withValues(alpha: 0.15)
                    : AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primary ? const Color(0xFF001218) : AppColors.cyan,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: primary ? const Color(0xFF001218) : Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primary
                          ? Colors.black.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: primary ? const Color(0xFF001218) : AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
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
