import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/notificacao_controller.dart';
import '../models/notificacao.dart';
import '../widgets/notificacao_item.dart';

/// Vista de lista de notificacoes (modal bottomsheet).
class NotificacoesView extends StatelessWidget {
  const NotificacoesView({super.key});

  /// Abre o bottomsheet de notificacoes.
  static Future<void> abrir(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificacoesView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificacaoController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              _Handle(),
              _Header(controller: controller),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.notificacoes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.erro.value != null && controller.notificacoes.isEmpty) {
                    return _ErroState(
                      mensagem: controller.erro.value!,
                      onRetry: () => controller.recarregar(),
                    );
                  }

                  if (controller.notificacoes.isEmpty) {
                    return const _VazioState();
                  }

                  return RefreshIndicator(
                    color: AppColors.cyan,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => controller.recarregar(),
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: controller.notificacoes.length,
                      itemBuilder: (context, index) {
                        final notif = controller.notificacoes[index];
                        return NotificacaoItem(
                          notificacao: notif,
                          onTap: () => _onTapNotificacao(context, notif),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onTapNotificacao(BuildContext context, Notificacao notif) {
    final controller = Get.find<NotificacaoController>();
    // Marca como lida (optimistic)
    if (!notif.lida) {
      controller.marcarLida(notif.id);
    }
    // Fecha bottomsheet
    Navigator.of(context).pop();
    // Navega para URL se houver
    if (notif.url != null && notif.url!.isNotEmpty) {
      // TODO: implementar navegação por URL quando o sistema de routes interno suportar.
      // Por agora apenas fecha; futuramente Get.toNamed(notif.url!) ou similar.
    }
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderHi,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final NotificacaoController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: AppColors.cyan, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Notificações',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final count = controller.naoLidas.value;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count nova${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          const Spacer(),
          Obx(() {
            if (controller.naoLidas.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: () => controller.marcarTodasLidas(),
              child: const Text(
                'Marcar todas',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VazioState extends StatelessWidget {
  const _VazioState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.textFaint,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sem notificações',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tudo em dia. Volte mais tarde.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErroState extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;

  const _ErroState({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMain, fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.cyan),
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
