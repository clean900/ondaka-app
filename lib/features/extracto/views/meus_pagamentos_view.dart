import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/pagamento_controller.dart';
import '../models/pagamento.dart';
import 'pagamento_form_view.dart';

/// Lista de pagamentos submetidos pelo condómino.
class MeusPagamentosView extends StatelessWidget {
  const MeusPagamentosView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PagamentoController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Os meus pagamentos'),
        backgroundColor: AppColors.bgDark,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.pagamentos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.pagamentos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text(
                    'Sem pagamentos submetidos.',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.pagamentos.length,
            itemBuilder: (_, i) =>
                _PagamentoCard(pagamento: controller.pagamentos[i]),
          ),
        );
      }),
    );
  }
}

class _PagamentoCard extends StatelessWidget {
  const _PagamentoCard({required this.pagamento});
  final Pagamento pagamento;

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(
      locale: 'pt_PT',
      symbol: 'Kz',
      decimalDigits: 2,
    );
    final formatadorData = DateFormat('d MMM yyyy', 'pt_PT');

    final corEstado = _corEstado();
    final iconeEstado = _iconeEstado();

    return InkWell(
      onTap: pagamento.podeEditar
          ? () => Get.to(() => PagamentoFormView(pagamento: pagamento))
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: corEstado.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconeEstado, color: corEstado, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pagamento.referencia,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pagamento.metodoLabel} · ${formatadorData.format(pagamento.dataPagamento)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatador.format(pagamento.valor),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: corEstado.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pagamento.estadoLabel,
                style: TextStyle(
                  color: corEstado,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (pagamento.foiRejeitado &&
                pagamento.motivoRejeicao != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFEF4444), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pagamento.motivoRejeicao!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _corEstado() {
    switch (pagamento.estado) {
      case 'confirmado':
        return const Color(0xFF10B981);
      case 'rejeitado':
      case 'devolvido':
        return const Color(0xFFEF4444);
      case 'em_revisao':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.cyan;
    }
  }

  IconData _iconeEstado() {
    switch (pagamento.estado) {
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'rejeitado':
      case 'devolvido':
        return Icons.cancel_outlined;
      case 'em_revisao':
        return Icons.hourglass_empty;
      default:
        return Icons.schedule;
    }
  }
}
