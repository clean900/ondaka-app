import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../chatbot/views/chatbot_bottomsheet.dart';
import '../../empresa_gestora/models/contactos_empresa.dart';
import '../../faqs/views/faqs_view.dart';
import '../controllers/suporte_controller.dart';

/// Tab "Suporte" do MainShell.
class SuporteView extends StatelessWidget {
  const SuporteView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuporteController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.carregar(),
          child: Obx(() {
            if (controller.isLoading.value && controller.contactos.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.erro.value != null && controller.contactos.value == null) {
              return _ErrorState(
                mensagem: controller.erro.value!,
                onRetry: () => controller.carregar(),
              );
            }

            final c = controller.contactos.value;
            if (c == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível carregar os contactos de suporte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(empresa: c),
                  const SizedBox(height: 24),

                  if (!c.configurado) ...[
                    const _AvisoNaoConfigurado(),
                    const SizedBox(height: 16),
                  ],

                  if (c.whatsapp != null && c.whatsapp!.isNotEmpty) ...[
                    _Canal(
                      icone: Icons.chat_bubble_outline,
                      cor: AppColors.success,
                      titulo: 'WhatsApp',
                      subtitulo: c.whatsapp!,
                      badge: 'Resposta rápida',
                      onTap: () => _abrirWhatsApp(context, c.whatsapp!),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (c.telefone != null && c.telefone!.isNotEmpty) ...[
                    _Canal(
                      icone: Icons.phone_outlined,
                      cor: AppColors.cyan,
                      titulo: 'Telefone',
                      subtitulo: c.telefone!,
                      badge: null,
                      onTap: () => _abrirTelefone(context, c.telefone!),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (c.email != null && c.email!.isNotEmpty) ...[
                    _Canal(
                      icone: Icons.mail_outline,
                      cor: AppColors.purple,
                      titulo: 'Email',
                      subtitulo: c.email!,
                      badge: 'Detalhado',
                      onTap: () => _abrirEmail(context, c.email!),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _Canal(
                    icone: Icons.smart_toy_outlined,
                    cor: AppColors.purple,
                    titulo: 'Chatbot ONDAKA',
                    subtitulo: 'Respostas imediatas a perguntas frequentes',
                    badge: 'Instantâneo',
                    onTap: () async {
                      final user = await StorageService.to.getUser();
                      if (!context.mounted) return;
                      ChatbotBottomsheet.abrir(context, userName: user['name']);
                    },
                  ),
                  const SizedBox(height: 12),

                  _Canal(
                    icone: Icons.help_outline,
                    cor: AppColors.warning,
                    titulo: 'FAQs do condomínio',
                    subtitulo: 'Regras, contactos e perguntas frequentes',
                    badge: null,
                    onTap: () => Get.to(() => const FaqsView()),
                  ),

                  if ((c.horarioAtendimento != null && c.horarioAtendimento!.isNotEmpty) ||
                      (c.morada != null && c.morada!.isNotEmpty)) ...[
                    const SizedBox(height: 20),
                    _InfoExtra(empresa: c),
                  ],

                  const SizedBox(height: 28),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _abrirWhatsApp(BuildContext context, String numero) async {
    final mensagem = Uri.encodeComponent('Olá, preciso de ajuda com o meu condomínio.');
    final numeroLimpo = numero.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$numeroLimpo?text=$mensagem');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _erro(context, 'Não foi possível abrir o WhatsApp.');
    }
  }

  Future<void> _abrirTelefone(BuildContext context, String numero) async {
    final uri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      _erro(context, 'Não foi possível abrir o telefone.');
    }
  }

  Future<void> _abrirEmail(BuildContext context, String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Pedido de suporte', 'body': 'Olá,\n\nPreciso de ajuda com:\n\n'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      _erro(context, 'Não foi possível abrir o email.');
    }
  }

  void _erro(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
    );
  }
}

class _Header extends StatelessWidget {
  final ContactosEmpresa empresa;
  const _Header({required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.purple, AppColors.pink]),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(14)),
            child: empresa.logotipoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      empresa.logotipoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.business_outlined, color: AppColors.cyan, size: 28),
                    ),
                  )
                : const Icon(Icons.business_outlined, color: AppColors.cyan, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A sua empresa gestora', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                empresa.nome,
                style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvisoNaoConfigurado extends StatelessWidget {
  const _AvisoNaoConfigurado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 0.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'A sua empresa gestora ainda não configurou canais de suporte. Use o chatbot ou as FAQs por agora.',
              style: TextStyle(color: AppColors.textMain, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Canal extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String subtitulo;
  final String? badge;
  final VoidCallback onTap;

  const _Canal({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cor.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Icon(icone, color: cor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: const TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            badge!,
                            style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textFaint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoExtra extends StatelessWidget {
  final ContactosEmpresa empresa;
  const _InfoExtra({required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (empresa.horarioAtendimento != null && empresa.horarioAtendimento!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    empresa.horarioAtendimento!,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (empresa.morada != null && empresa.morada!.isNotEmpty) const SizedBox(height: 10),
          ],
          if (empresa.morada != null && empresa.morada!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    empresa.morada!,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _ErrorState({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
