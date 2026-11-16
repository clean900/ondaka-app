import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/afiliados_controller.dart';
import '../models/afiliado_models.dart';
import '../widgets/afiliados_ui.dart';

/// Separador «Pagamentos»: o que a ONDAKA já transferiu ao afiliado.
/// Cada pagamento agrupa comissões aprovadas.
class PagamentosTab extends StatelessWidget {
  final AfiliadosController c;

  const PagamentosTab({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    c.carregarPagamentos();

    return Obx(() {
      if (c.aCarregarPagamentos.value && c.pagamentos.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.erroPagamentos.value != null && c.pagamentos.isEmpty) {
        return CaixaErro(
          mensagem: c.erroPagamentos.value!,
          onTentar: () => c.carregarPagamentos(forcar: true),
        );
      }

      final r = c.resumo;

      if (c.pagamentos.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => c.carregarPagamentos(forcar: true),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              Vazio(
                icone: Icons.account_balance_wallet_outlined,
                titulo: 'Ainda sem pagamentos',
                texto: r == null
                    ? 'Quando o saldo aprovado atingir o mínimo, a ONDAKA transfere e o '
                        'comprovativo fica aqui.'
                    : 'Tem ${kz(r.aprovadaKz)} aprovados. A partir de ${kz(r.pagamentoMinimoKz)} '
                        'entra no lote de pagamento seguinte, e o comprovativo fica aqui.',
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => c.carregarPagamentos(forcar: true),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: c.pagamentos.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i == 0) {
              final total = c.pagamentos.fold<double>(0, (a, p) => a + p.valorLiquidoKz);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${c.pagamentos.length} pagamento(s) · ${kz(total, cent: true)} recebidos',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                  if (r != null && r.aprovadaKz > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_send_outlined,
                              size: 18, color: AppColors.successSoft),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.atingeMinimo
                                  ? '${kz(r.aprovadaKz)} aprovados — entram no próximo lote de pagamento.'
                                  : '${kz(r.aprovadaKz)} aprovados. O mínimo para pagamento é ${kz(r.pagamentoMinimoKz)}.',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                ],
              );
            }
            return _CartaoPagamento(pagamento: c.pagamentos[i - 1]);
          },
        ),
      );
    });
  }
}

class _CartaoPagamento extends StatelessWidget {
  final PagamentoAfiliado pagamento;
  const _CartaoPagamento({required this.pagamento});

  @override
  Widget build(BuildContext context) {
    final temRetencao = pagamento.retencaoValorKz > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pagamento.numero,
                        style: const TextStyle(
                            color: AppColors.textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace')),
                    const SizedBox(height: 2),
                    Text(
                      '${data(pagamento.pagoEm)} · ${pagamento.numComissoes} comissão(ões)',
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Text(kz(pagamento.valorLiquidoKz, cent: true),
                  style: const TextStyle(
                      color: AppColors.successSoft, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 6),
          LinhaDetalhe('Bruto', kz(pagamento.valorBrutoKz, cent: true)),
          if (temRetencao)
            LinhaDetalhe(
              'Retenção na fonte (${pct(pagamento.retencaoPct)})',
              '− ${kz(pagamento.retencaoValorKz, cent: true)}',
              corValor: AppColors.warningSoft,
            ),
          LinhaDetalhe('Líquido recebido', kz(pagamento.valorLiquidoKz, cent: true),
              corValor: AppColors.successSoft),
          LinhaDetalhe('Método', pagamento.metodoLabel),
          if (pagamento.referenciaBancaria != null)
            LinhaDetalhe('Referência', pagamento.referenciaBancaria!, mono: true),
          if (pagamento.ibanDestino != null)
            LinhaDetalhe('IBAN de destino', pagamento.ibanDestino!, mono: true),
          if (pagamento.notas != null && pagamento.notas!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(pagamento.notas!,
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11.5, height: 1.4)),
            ),
          const SizedBox(height: 8),
          const Text(
            'O comprovativo da transferência está no portal web, em ondaka.ao/afiliado/pagamentos.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}
