import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../assembleias/views/minhas_assembleias_view.dart';
import '../../faqs/views/faqs_view.dart';
import '../../ordens/views/minhas_ordens_view.dart';
import '../../tickets/views/meus_tickets_view.dart';

/// Tab "Mais" — itens secundários acessíveis em lista.
/// Tickets, Assembleias, Minhas ordens, FAQs, Sair.
class MaisView extends StatelessWidget {
  const MaisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _MaisItem(
            icon: Icons.confirmation_number_outlined,
            cor: AppColors.cyan,
            titulo: 'Tickets',
            subtitulo: 'Reportar problemas e ver os meus pedidos',
            onTap: () => Get.to(() => const MeusTicketsView()),
          ),
          _MaisItem(
            icon: Icons.groups_outlined,
            cor: AppColors.info,
            titulo: 'Assembleias',
            subtitulo: 'Convocatórias, votações e actas',
            onTap: () => Get.to(() => const MinhasAssembleiasView()),
          ),
          _MaisItem(
            icon: Icons.receipt_long_outlined,
            cor: AppColors.purple,
            titulo: 'Minhas ordens',
            subtitulo: 'Facturas e pagamentos',
            onTap: () => Get.to(() => const MinhasOrdensView()),
          ),
          _MaisItem(
            icon: Icons.help_outline,
            cor: AppColors.warning,
            titulo: 'FAQs',
            subtitulo: 'Perguntas frequentes',
            onTap: () => Get.to(() => const FaqsView()),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Divider(color: AppColors.border, height: 1),
          ),

          _MaisItem(
            icon: Icons.logout,
            cor: AppColors.danger,
            titulo: 'Sair',
            subtitulo: 'Terminar sessão',
            onTap: () => _confirmLogout(context),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar sessão?'),
        content: const Text('Vais ter de iniciar sessão novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.to.logout();
              await StorageService.to.clearAll();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _MaisItem extends StatelessWidget {
  final IconData icon;
  final Color cor;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _MaisItem({
    required this.icon,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cor, size: 22),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          color: AppColors.textMain,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textFaint,
        size: 20,
      ),
    );
  }
}
