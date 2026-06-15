import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../assembleias/views/minhas_assembleias_view.dart';
import '../../encomendas/views/encomendas_shell_view.dart';
import '../../prestadores/views/prestadores_view.dart';
import '../../marketplace/views/marketplace_view.dart';
import '../../extracto/views/extracto_view.dart';
import '../../acordos/views/acordos_view.dart';
import '../../faqs/views/faqs_view.dart';
import '../../suporte/views/suporte_view.dart';
import '../../admin_chatbot_faqs/views/admin_chatbot_faqs_page.dart';
import '../../conheca/views/conheca_view.dart';
import '../../sos/views/sos_historico_view.dart';
import '../../ordens/views/minhas_ordens_view.dart';
import '../../tickets/views/meus_tickets_view.dart';
import '../../equipa/views/equipa_view.dart';
import '../../perfil/views/perfil_view.dart';
import '../../reservas/views/reservas_view.dart';
import '../../familiares/views/familiares_view.dart';

/// Tab "Mais" — grelha de cartoes com as funcionalidades secundarias.
class MaisView extends StatelessWidget {
  const MaisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Mais')),
      body: Builder(builder: (context) {
        final auth = AuthService.to;
        bool pode(String acesso) => !auth.isFamiliar || auth.acessos.contains(acesso);
        final ehFamiliar = auth.isFamiliar;
        // "Minhas ordens" é uma função B2B (ordens de compra da empresa gestora).
        // Só faz sentido para perfis de gestão; o condómino nunca tem ordens.
        const rolesGestao = {
          'administrador-condominio',
          'gestor',
          'admin-empresa',
          'super-admin',
        };
        final ehGestao = rolesGestao.contains(auth.roleAtual.value);

        final cards = <Widget>[
          _MaisCard(
            icon: Icons.account_circle_outlined,
            cor: AppColors.cyan,
            titulo: 'Meu Perfil',
            subtitulo: 'Dados e password',
            onTap: () => Get.to(() => const PerfilView()),
          ),
          if (!ehFamiliar)
            _MaisCard(
              icon: Icons.family_restroom,
              cor: AppColors.cyan,
              titulo: 'Família',
              subtitulo: 'Gerir familiares',
              onTap: () => Get.to(() => const FamiliaresView()),
            ),
          if (pode('portaria'))
            _MaisCard(
              icon: Icons.inventory_2_outlined,
              cor: AppColors.purple,
              titulo: 'Encomendas',
              subtitulo: 'Pré-anunciar',
              onTap: () => Get.to(() => const EncomendasShellView()),
            ),
          if (pode('marketplace'))
            _MaisCard(
              icon: Icons.storefront_outlined,
              cor: AppColors.cyan,
              titulo: 'Marketplace',
              subtitulo: 'Entre vizinhos',
              onTap: () => Get.to(() => const MarketplaceView()),
            ),
          if (pode('marketplace'))
            _MaisCard(
              icon: Icons.handyman_outlined,
              cor: AppColors.pink,
              titulo: 'Serviços',
              subtitulo: 'Prestadores',
              onTap: () => Get.to(() => const PrestadoresView()),
            ),
          if (pode('reservas'))
            _MaisCard(
              icon: Icons.event_available_outlined,
              cor: AppColors.cyan,
              titulo: 'Reservas',
              subtitulo: 'Salão, ginásio',
              onTap: () => Get.to(() => const ReservasView()),
            ),
          if (!ehFamiliar)
            _MaisCard(
              icon: Icons.account_balance_wallet_outlined,
              cor: AppColors.cyan,
              titulo: 'Taxas',
              subtitulo: 'Valores e pagamentos',
              onTap: () => Get.to(() => const ExtractoView()),
            ),
          if (!ehFamiliar)
            _MaisCard(
              icon: Icons.handshake_outlined,
              cor: AppColors.purple,
              titulo: 'Acordo',
              subtitulo: 'Plano de pagamento',
              onTap: () => Get.to(() => const AcordosView()),
            ),
          if (pode('pedidos'))
            _MaisCard(
              icon: Icons.confirmation_number_outlined,
              cor: AppColors.cyan,
              titulo: 'Pedidos',
              subtitulo: 'Reportar problemas',
              onTap: () => Get.to(() => const MeusTicketsView()),
            ),
          if (pode('equipa'))
            _MaisCard(
              icon: Icons.people_outline,
              cor: AppColors.pink,
              titulo: 'Equipa',
              subtitulo: 'Do condomínio',
              onTap: () => Get.to(() => const EquipaView()),
            ),
          if (pode('avisos'))
            _MaisCard(
              icon: Icons.groups_outlined,
              cor: AppColors.info,
              titulo: 'Assembleias',
              subtitulo: 'Convocatórias, actas',
              onTap: () => Get.to(() => const MinhasAssembleiasView()),
            ),
          if (auth.eMembroComissao.value)
            _MaisCard(
              icon: Icons.fact_check_outlined,
              cor: AppColors.cyan,
              titulo: 'Aprovar Despesas',
              subtitulo: 'Despesas pendentes da comissão',
              onTap: () => Get.toNamed(AppRoutes.despesasComissao),
            ),
          if (ehGestao)
            _MaisCard(
              icon: Icons.receipt_long_outlined,
              cor: AppColors.purple,
              titulo: 'Minhas ordens',
              subtitulo: 'Facturas',
              onTap: () => Get.to(() => const MinhasOrdensView()),
            ),
          _MaisCard(
            icon: Icons.help_outline,
            cor: AppColors.warning,
            titulo: 'Nosso Condomínio',
            subtitulo: 'Perguntas frequentes',
            onTap: () => Get.to(() => const FaqsView()),
          ),
          _MaisCard(
            icon: Icons.support_agent_outlined,
            cor: AppColors.info,
            titulo: 'Suporte',
            subtitulo: 'Contactar gestão',
            onTap: () => Get.to(() => const SuporteView()),
          ),
          if (ehGestao)
            _MaisCard(
              icon: Icons.chat_bubble_outline,
              cor: AppColors.cyan,
              titulo: 'FAQs Chatbot',
              subtitulo: 'Gerir (admin)',
              onTap: () => Get.to(() => const AdminChatbotFaqsPage()),
            ),
          _MaisCard(
            icon: Icons.auto_awesome_outlined,
            cor: AppColors.pink,
            titulo: 'Conheça',
            subtitulo: 'A ONDAKA',
            onTap: () => Get.to(() => const ConhecaView()),
          ),
          if (pode('sos'))
            _MaisCard(
              icon: Icons.emergency_outlined,
              cor: AppColors.danger,
              titulo: 'Alertas SOS',
              subtitulo: 'Histórico',
              onTap: () => Get.to(() => const SosHistoricoView()),
            ),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: cards,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Sair', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            const _RodapeLegal(),
          ],
        );
      }),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Terminar sessão?', style: TextStyle(color: AppColors.textMain)),
        content: const Text('Vais ter de iniciar sessão novamente.', style: TextStyle(color: AppColors.textMuted)),
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

/// Rodapé legal: links para Política de Privacidade e Termos (exigência das lojas).
class _RodapeLegal extends StatelessWidget {
  const _RodapeLegal();

  Future<void> _abrir(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _abrir('https://ondaka.ao/privacidade'),
              child: const Text(
                'Política de Privacidade',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            const Text('·', style: TextStyle(color: AppColors.textMuted)),
            TextButton(
              onPressed: () => _abrir('https://ondaka.ao/termos'),
              child: const Text(
                'Termos & Condições',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'ONDAKA · v1.0.0',
          style: TextStyle(color: AppColors.textFaint, fontSize: 11),
        ),
      ],
    );
  }
}

class _MaisCard extends StatelessWidget {
  final IconData icon;
  final Color cor;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _MaisCard({
    required this.icon,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: cor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
