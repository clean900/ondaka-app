import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../assembleias/views/minhas_assembleias_view.dart';
import '../../encomendas/views/encomendas_shell_view.dart';
import '../../prestadores/views/prestadores_view.dart';
import '../../marketplace/views/marketplace_view.dart';
import '../../extracto/views/extracto_view.dart';
import '../../faqs/views/faqs_view.dart';
import '../../admin_chatbot_faqs/views/admin_chatbot_faqs_page.dart';
import '../../conheca/views/conheca_view.dart';
import '../../sos/views/sos_historico_view.dart';
import '../../ordens/views/minhas_ordens_view.dart';
import '../../tickets/views/meus_tickets_view.dart';
import '../../equipa/views/equipa_view.dart';
import '../../perfil/views/perfil_view.dart';
import '../../reservas/views/reservas_view.dart';
// import '../../checklist/views/checklist_lista_view.dart'; // RH/Turnos - fase futura

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
            icon: Icons.account_circle_outlined,
            cor: AppColors.cyan,
            titulo: 'Meu Perfil',
            subtitulo: 'Dados pessoais e password',
            onTap: () => Get.to(() => const PerfilView()),
          ),
          _MaisItem(
            icon: Icons.inventory_2_outlined,
            cor: AppColors.purple,
            titulo: 'Encomendas',
            subtitulo: 'Pré-anunciar e levantar encomendas',
            onTap: () => Get.to(() => const EncomendasShellView()),
          ),
          _MaisItem(
            icon: Icons.storefront_outlined,
            cor: AppColors.cyan,
            titulo: 'Marketplace',
            subtitulo: 'Compra e venda entre vizinhos',
            onTap: () => Get.to(() => const MarketplaceView()),
          ),
          _MaisItem(
            icon: Icons.handyman_outlined,
            cor: AppColors.pink,
            titulo: 'Serviços',
            subtitulo: 'Encontrar canalizadores, electricistas e mais',
            onTap: () => Get.to(() => const PrestadoresView()),
          ),
          _MaisItem(
            icon: Icons.event_available_outlined,
            cor: AppColors.cyan,
            titulo: 'Reservas',
            subtitulo: 'Reservar salão, churrasqueira, ginásio',
            onTap: () => Get.to(() => const ReservasView()),
          ),
          _MaisItem(
            icon: Icons.account_balance_wallet_outlined,
            cor: AppColors.cyan,
            titulo: 'Minhas Taxas de Condomínio',
            subtitulo: 'Valores a pagar e pagamentos efectuados',
            onTap: () => Get.to(() => const ExtractoView()),
          ),
          _MaisItem(
            icon: Icons.confirmation_number_outlined,
            cor: AppColors.cyan,
            titulo: 'Pedidos de Intervenção',
            subtitulo: 'Reportar problemas e ver os meus pedidos',
            onTap: () => Get.to(() => const MeusTicketsView()),
          ),
          _MaisItem(
            icon: Icons.people_outline,
            cor: AppColors.pink,
            titulo: 'Equipa do Condomínio',
            subtitulo: 'Administradores, gestores, funcionários e prestadores',
            onTap: () => Get.to(() => const EquipaView()),
          ),
          // === Checklists — escondido (RH/Turnos, fase futura) ===
          // _MaisItem(
          //   icon: Icons.checklist_rtl,
          //   cor: AppColors.success,
          //   titulo: 'Checklists',
          //   subtitulo: 'Rondas, inspecções e verificações',
          //   onTap: () => Get.to(() => const ChecklistListaView()),
          // ),
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
          _MaisItem(
            icon: Icons.chat_bubble_outline,
            cor: AppColors.cyan,
            titulo: 'FAQs do Chatbot',
            subtitulo: 'Gerir FAQs do condomínio (admin)',
            onTap: () => Get.to(() => const AdminChatbotFaqsPage()),
          ),
          _MaisItem(
            icon: Icons.auto_awesome_outlined,
            cor: AppColors.pink,
            titulo: 'Conheça a ONDAKA',
            subtitulo: 'Catálogo de funcionalidades da plataforma',
            onTap: () => Get.to(() => const ConhecaView()),
          ),
          _MaisItem(
            icon: Icons.emergency_outlined,
            cor: AppColors.danger,
            titulo: 'Meus alertas SOS',
            subtitulo: 'Histórico de emergências reportadas',
            onTap: () => Get.to(() => const SosHistoricoView()),
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
