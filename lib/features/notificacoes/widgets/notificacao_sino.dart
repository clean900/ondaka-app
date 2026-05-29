import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/notificacao_controller.dart';
import '../views/notificacoes_view.dart';

/// Sino de notificações com badge de não-lidas.
///
/// - Tap → abre bottomsheet com lista de notificações
/// - Badge vermelho mostra contagem (escondido se 0)
/// - 99+ se ultrapassar 99
class NotificacaoSino extends StatelessWidget {
  /// Tamanho do botão (default 44, bom para hit target).
  final double size;

  /// Cor do ícone do sino.
  final Color iconColor;

  /// Mostrar shadow/elevation (útil quando flutua sobre conteúdo).
  final bool comShadow;

  const NotificacaoSino({
    super.key,
    this.size = 44,
    this.iconColor = Colors.white,
    this.comShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    // Garante que o controller existe (cria se não existe ainda)
    final controller = Get.put(NotificacaoController(), permanent: true);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirLista(context),
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: comShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: iconColor,
                size: size * 0.5,
              ),
              // Badge de não-lidas
              Positioned(
                top: 8,
                right: 8,
                child: Obx(() {
                  final count = controller.naoLidas.value;
                  if (count == 0) return const SizedBox.shrink();
                  return _Badge(count: count);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirLista(BuildContext context) {
    NotificacoesView.abrir(context);
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    final isSingleDigit = count < 10;

    return Container(
      constraints: BoxConstraints(
        minWidth: isSingleDigit ? 16 : 20,
        minHeight: 16,
      ),
      padding: EdgeInsets.symmetric(horizontal: isSingleDigit ? 0 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444), // vermelho
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bgDark, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}
