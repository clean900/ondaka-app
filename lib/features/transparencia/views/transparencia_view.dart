import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/transparencia_controller.dart';
import '../models/relatorio_financeiro.dart';

/// Transparência financeira do condomínio, dirigida ao condómino.
/// Mostra apenas agregados (sem nomes de devedores).
class TransparenciaView extends StatelessWidget {
  const TransparenciaView({super.key});

  static String kz(num v) => '${NumberFormat('#,##0', 'pt_PT').format(v)} Kz';

  @override
  Widget build(BuildContext context) {
    final c = Get.put(TransparenciaController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Contas do Condomínio'),
        backgroundColor: AppColors.bgDark,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.relatorio.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.erro.value != null && c.relatorio.value == null) {
          return _Erro(mensagem: c.erro.value!, onRetry: c.carregar);
        }
        final r = c.relatorio.value;
        if (r == null) {
          return _Erro(mensagem: 'Sem dados.', onRetry: c.carregar);
        }
        if (!r.publicado) {
          return _Erro(
            mensagem: r.mensagem ?? 'A gestão ainda não publicou a transparência financeira deste condomínio.',
            onRetry: c.carregar,
          );
        }

        return RefreshIndicator(
          onRefresh: c.carregar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (r.condominio != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(r.condominio!,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              const Text('Resumo financeiro do condomínio',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
              const SizedBox(height: 12),

              _SeletorPeriodo(atual: c.meses.value, onMudar: c.mudarPeriodo),
              const SizedBox(height: 16),

              // Receita / Despesa / Saldo
              Row(children: [
                Expanded(child: _CartaoValor(label: 'Receita', valor: kz(r.receita), cor: AppColors.success)),
                const SizedBox(width: 10),
                Expanded(child: _CartaoValor(label: 'Despesa', valor: kz(r.despesa), cor: AppColors.danger)),
              ]),
              const SizedBox(height: 10),
              _CartaoValor(
                label: 'Saldo do período',
                valor: kz(r.saldo),
                cor: r.saldo >= 0 ? AppColors.cyan : AppColors.danger,
                largo: true,
              ),
              const SizedBox(height: 16),

              // Fundo de reserva
              _Seccao(titulo: 'Fundo de Reserva', child: _FundoReserva(r: r)),
              const SizedBox(height: 16),

              // Cobrança
              _Seccao(
                titulo: 'Cobrança',
                child: Row(children: [
                  Expanded(child: _MiniKpi(label: 'Taxa de cobrança', valor: '${r.taxaCobranca}%', cor: AppColors.warning)),
                  Expanded(child: _MiniKpi(label: 'Dívida total', valor: kz(r.dividaTotal), cor: AppColors.danger)),
                ]),
              ),
              const SizedBox(height: 16),

              // Despesas por categoria
              _Seccao(
                titulo: 'Despesas por categoria',
                child: _DespesasCategorias(r: r),
              ),
              const SizedBox(height: 24),

              const Center(
                child: Text('Dados de transparência do condomínio · ONDAKA',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 11)),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SeletorPeriodo extends StatelessWidget {
  const _SeletorPeriodo({required this.atual, required this.onMudar});
  final int atual;
  final void Function(int) onMudar;

  @override
  Widget build(BuildContext context) {
    const opcoes = [3, 6, 12, 24];
    return Row(
      children: opcoes.map((m) {
        final on = m == atual;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onMudar(m),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: on
                      ? const LinearGradient(colors: [AppColors.cyan, AppColors.purple])
                      : null,
                  color: on ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: on ? Colors.transparent : AppColors.border),
                ),
                child: Text('$m m',
                    style: TextStyle(
                        color: on ? Colors.white : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CartaoValor extends StatelessWidget {
  const _CartaoValor({required this.label, required this.valor, required this.cor, this.largo = false});
  final String label;
  final String valor;
  final Color cor;
  final bool largo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largo ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
          const SizedBox(height: 4),
          Text(valor, style: TextStyle(color: cor, fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({required this.label, required this.valor, required this.cor});
  final String label;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
        const SizedBox(height: 3),
        Text(valor, style: TextStyle(color: cor, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _FundoReserva extends StatelessWidget {
  const _FundoReserva({required this.r});
  final RelatorioFinanceiro r;

  @override
  Widget build(BuildContext context) {
    final cumpre = r.fundoReservaCumpre;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${r.fundoReservaPct}%',
                style: const TextStyle(color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (cumpre ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(cumpre ? 'Cumpre' : 'Abaixo do mínimo',
                  style: TextStyle(
                      color: cumpre ? AppColors.successSoft : AppColors.dangerSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Mínimo legal ${r.fundoReservaMinLegal}% · DP 141/15',
            style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _MiniKpi(label: 'Saldo disponível', valor: TransparenciaView.kz(r.saldoDisponivel), cor: AppColors.cyan)),
          Expanded(child: _MiniKpi(label: 'Dívida em aberto', valor: TransparenciaView.kz(r.dividaAberto), cor: AppColors.danger)),
        ]),
      ],
    );
  }
}

class _DespesasCategorias extends StatelessWidget {
  const _DespesasCategorias({required this.r});
  final RelatorioFinanceiro r;

  @override
  Widget build(BuildContext context) {
    if (r.despesasPorCategoria.isEmpty) {
      return const Text('Sem despesas no período.', style: TextStyle(color: AppColors.textFaint, fontSize: 12));
    }
    final maxV = r.despesasPorCategoria.map((c) => c.total).fold<double>(0, (a, b) => b > a ? b : a);
    return Column(
      children: [
        for (final cat in r.despesasPorCategoria) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(cat.categoria, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                    Text(TransparenciaView.kz(cat.total),
                        style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxV > 0 ? cat.total / maxV : 0,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceHi,
                    valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                  ),
                ),
              ],
            ),
          ),
        ],
        const Divider(color: AppColors.border, height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL', style: TextStyle(color: AppColors.textFaint, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(TransparenciaView.kz(r.despesasTotal),
                style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _Seccao extends StatelessWidget {
  const _Seccao({required this.titulo, required this.child});
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: AppColors.cyan, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.mensagem, required this.onRetry});
  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_outlined, color: AppColors.textFaint, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}
