import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/autorizacoes_saida_controller.dart';
import '../models/pedido_autorizacao_bem.dart';

/// Ecrã do condómino: autorizar/recusar a saída de bens não declarados.
class AutorizacoesSaidaView extends StatelessWidget {
  const AutorizacoesSaidaView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AutorizacoesSaidaController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Saída de bens'),
      ),
      body: Obx(() {
        if (c.isLoading.value && c.pedidos.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (c.addonInativo.value) {
          return _aviso(Icons.lock_outline, 'Esta funcionalidade não está activa.');
        }
        if (c.erro.value != null && c.pedidos.isEmpty) {
          return _aviso(Icons.error_outline, c.erro.value!, onRetry: c.carregar);
        }
        if (c.pedidos.isEmpty) {
          return _aviso(Icons.check_circle_outline, 'Sem pedidos de autorização pendentes.');
        }
        return RefreshIndicator(
          color: AppColors.cyan,
          onRefresh: c.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: c.pedidos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _cardPedido(c, c.pedidos[i]),
          ),
        );
      }),
    );
  }

  Widget _cardPedido(AutorizacoesSaidaController c, PedidoAutorizacaoBem p) {
    final emProgresso = c.emProgresso(p.itemId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.warningSoft, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.quantidade > 1 ? '${p.quantidade}× ${p.descricao}' : p.descricao,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (p.identificador != null && p.identificador!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(p.identificador!, style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
          ],
          const SizedBox(height: 6),
          Text('${p.visitanteNome} · ${p.fraccaoLabel}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          if (p.fotoUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                p.fotoUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (ctx, child, progress) =>
                    progress == null ? child : const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppColors.cyan))),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text('O visitante quer sair com este bem (não declarado à entrada). Autoriza?',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: emProgresso ? null : () => c.responder(p.itemId, aprovar: false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Recusar', style: TextStyle(color: AppColors.dangerSoft, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: emProgresso ? null : () => c.responder(p.itemId, aprovar: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: emProgresso
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Autorizar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aviso(IconData icon, String msg, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textFaint, size: 48),
            const SizedBox(height: 14),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ],
        ),
      ),
    );
  }
}
