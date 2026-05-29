import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../extracto/controllers/extracto_controller.dart';
import '../../extracto/models/mes_grafico.dart';
import '../../extracto/models/movimento.dart';
import '../../extracto/views/extracto_view.dart';
import '../../conheca/views/conheca_view.dart';
import '../../extracto/views/pagamento_form_view.dart';
import '../../tickets/views/meus_tickets_view.dart';

/// Dashboard financeiro do condómino — mostra-se acima do DashboardV3.
///
/// Secções (de cima para baixo):
///  1. Card destaque: saldo em aberto + botão "Pagar agora"
///  2. Mini-KPIs: próxima taxa + já pago acumulado
///  3. Acessos rápidos: 4 atalhos
///  4. Gráfico de barras: 12 meses (pago vs em aberto)
///  5. Movimentos recentes: top 3
class DashboardFinanceiroWidget extends StatelessWidget {
  const DashboardFinanceiroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExtractoController());

    return Obx(() {
      if (controller.isLoadingSaldo.value && controller.saldo.value == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final saldo = controller.saldo.value;
      if (saldo == null) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardSaldo(
            totalEmDivida: saldo.totalEmDivida,
            numeroFacturas: saldo.numeroLancamentosEmDivida,
            onPagar: () => Get.to(() => const PagamentoFormView()),
          ),
          const SizedBox(height: 16),
          _GraficoBarras(
            entradas: controller.grafico,
            isLoading: controller.isLoadingGrafico.value,
          ),
          const SizedBox(height: 12),
          _MiniKpis(grafico: controller.grafico),
          const SizedBox(height: 16),
          _AcessosRapidos(),
          const SizedBox(height: 16),
          _MovimentosRecentes(
            movimentos: controller.movimentos.take(3).toList(),
            isLoading: controller.isLoadingMovimentos.value,
            onVerTudo: () => Get.to(() => const ExtractoView()),
          ),
          const SizedBox(height: 100),
        ],
      );
    });
  }
}

// ============================================================================
// 1. CARD SALDO + BOTÃO PAGAR
// ============================================================================
class _CardSaldo extends StatelessWidget {
  final double totalEmDivida;
  final int numeroFacturas;
  final VoidCallback onPagar;

  const _CardSaldo({
    required this.totalEmDivida,
    required this.numeroFacturas,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final estaEmDia = totalEmDivida <= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estaEmDia
              ? [AppColors.success.withValues(alpha: 0.08), AppColors.cyan.withValues(alpha: 0.04)]
              : [AppColors.pink.withValues(alpha: 0.10), AppColors.purple.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estaEmDia
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.pink.withValues(alpha: 0.25),
          width: 0.5,
        ),
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
                    Text(
                      estaEmDia ? 'TUDO EM DIA' : 'SALDO EM ABERTO',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatKz(totalEmDivida),
                          style: const TextStyle(
                            color: AppColors.textMain,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Kz',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!estaEmDia)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$numeroFacturas factura${numeroFacturas == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.pink,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (!estaEmDia) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: onPagar,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple, AppColors.pink],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Pagar agora',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 2. MINI-KPIs (próxima taxa + já pago)
// ============================================================================
class _MiniKpis extends StatelessWidget {
  final RxList<MesGrafico> grafico;

  const _MiniKpis({required this.grafico});

  @override
  Widget build(BuildContext context) {
    final jaPago = grafico.fold<double>(0, (acc, m) => acc + m.pago);
    final mesesComPagamento = grafico.where((m) => m.pago > 0).length;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icone: Icons.receipt_long,
            cor: AppColors.cyan,
            label: 'PRÓXIMA TAXA',
            valor: '—',
            sublabel: 'a anunciar',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icone: Icons.check_circle_outline,
            cor: AppColors.success,
            label: 'JÁ PAGO',
            valor: _formatKz(jaPago),
            sublabel: '$mesesComPagamento mês${mesesComPagamento == 1 ? '' : 'es'}',
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String label;
  final String valor;
  final String sublabel;

  const _KpiCard({
    required this.icone,
    required this.cor,
    required this.label,
    required this.valor,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Icon(icone, size: 16, color: cor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: TextStyle(color: cor.withValues(alpha: 0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. ACESSOS RÁPIDOS
// ============================================================================
class _AcessosRapidos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acesso rápido',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _AtalhoIcone(
              icone: Icons.auto_awesome_outlined,
              cor: AppColors.pink,
              label: 'Conheça',
              onTap: () => Get.to(() => const ConhecaView()),
            )),
            const SizedBox(width: 8),
            Expanded(child: _AtalhoIcone(
              icone: Icons.receipt_long,
              cor: AppColors.cyan,
              label: 'Extracto',
              onTap: () => Get.to(() => const ExtractoView()),
            )),
            const SizedBox(width: 8),
            Expanded(child: _AtalhoIcone(
              icone: Icons.build_outlined,
              cor: AppColors.purple,
              label: 'Pedidos',
              onTap: () => Get.to(() => const MeusTicketsView()),
            )),


          ],
        ),
      ],
    );
  }
}

class _AtalhoIcone extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String label;
  final VoidCallback onTap;

  const _AtalhoIcone({
    required this.icone,
    required this.cor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Icon(icone, size: 20, color: cor),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. GRÁFICO DE BARRAS (12 meses)
// ============================================================================
class _GraficoBarras extends StatelessWidget {
  final RxList<MesGrafico> entradas;
  final bool isLoading;

  const _GraficoBarras({required this.entradas, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading && entradas.isEmpty) {
      return _box(const Center(
        heightFactor: 4,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ));
    }

    if (entradas.isEmpty) {
      return _box(const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(
          'Sem dados para mostrar',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        )),
      ));
    }

    final maxValor = entradas
        .map((e) => e.total)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return _box(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos 12 meses',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entradas.map((e) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _Barra(entrada: e, maxValor: maxValor),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: entradas.map((e) {
            return Expanded(
              child: Center(
                child: Text(
                  e.mesCurto,
                  style: const TextStyle(color: AppColors.textFaint, fontSize: 9),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Legenda(cor: AppColors.success, label: 'Pago'),
            const SizedBox(width: 16),
            _Legenda(cor: AppColors.pink, label: 'Em aberto'),
          ],
        ),
      ],
    ));
  }

  Widget _box(Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: child,
      );
}

class _Barra extends StatelessWidget {
  final MesGrafico entrada;
  final double maxValor;

  const _Barra({required this.entrada, required this.maxValor});

  @override
  Widget build(BuildContext context) {
    if (maxValor <= 0) {
      return const SizedBox.shrink();
    }
    final alturaPago = (entrada.pago / maxValor) * 70;
    final alturaAberto = (entrada.emAberto / maxValor) * 70;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (entrada.emAberto > 0)
          Container(
            height: alturaAberto.clamp(2.0, 70.0),
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(3),
                topRight: const Radius.circular(3),
                bottomLeft: entrada.pago > 0 ? Radius.zero : const Radius.circular(3),
                bottomRight: entrada.pago > 0 ? Radius.zero : const Radius.circular(3),
              ),
            ),
          ),
        if (entrada.pago > 0)
          Container(
            height: alturaPago.clamp(2.0, 70.0),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.7),
              borderRadius: BorderRadius.only(
                topLeft: entrada.emAberto > 0 ? Radius.zero : const Radius.circular(3),
                topRight: entrada.emAberto > 0 ? Radius.zero : const Radius.circular(3),
                bottomLeft: const Radius.circular(3),
                bottomRight: const Radius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String label;

  const _Legenda({required this.cor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ============================================================================
// 5. MOVIMENTOS RECENTES (top 3)
// ============================================================================
class _MovimentosRecentes extends StatelessWidget {
  final List<Movimento> movimentos;
  final bool isLoading;
  final VoidCallback onVerTudo;

  const _MovimentosRecentes({
    required this.movimentos,
    required this.isLoading,
    required this.onVerTudo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Movimentos recentes',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              onTap: onVerTudo,
              child: const Text(
                'Ver tudo →',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading && movimentos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (movimentos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(child: Text(
              'Ainda não há movimentos.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            )),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: movimentos.asMap().entries.map((entry) {
                final isLast = entry.key == movimentos.length - 1;
                return _LinhaMovimento(movimento: entry.value, isLast: isLast);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _LinhaMovimento extends StatelessWidget {
  final Movimento movimento;
  final bool isLast;

  const _LinhaMovimento({required this.movimento, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isCredito = movimento.sentido == 'credito';
    final cor = isCredito ? AppColors.success : AppColors.pink;
    final icone = isCredito ? Icons.arrow_downward : Icons.receipt;
    final sinal = isCredito ? '+' : '−';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 16, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimento.descricao,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatarDataRelativa(movimento.data),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$sinal${_formatKz(movimento.valor)}',
            style: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================
String _formatKz(double valor) {
  final f = NumberFormat('#,##0.##', 'pt_AO');
  return f.format(valor);
}

String _formatarDataRelativa(DateTime data) {
  final agora = DateTime.now();
  final diff = agora.difference(data);
  if (diff.inDays == 0) return 'Hoje';
  if (diff.inDays == 1) return 'Ontem';
  if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
  if (diff.inDays < 30) {
    final semanas = (diff.inDays / 7).floor();
    return 'Há $semanas semana${semanas == 1 ? '' : 's'}';
  }
  return DateFormat('d MMM', 'pt_AO').format(data);
}
