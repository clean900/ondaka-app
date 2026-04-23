import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          return Padding(
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
