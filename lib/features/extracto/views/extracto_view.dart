import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/extracto_controller.dart';
import 'meus_pagamentos_view.dart';
import 'pagamento_form_view.dart';
import '../models/extracto_saldo.dart';
import '../models/movimento.dart';

/// Ecrã principal do extracto do condómino.
///
/// Apresenta:
/// - Header com saldo total
/// - Decomposição por tipo (quotas, multas, despesas)
/// - Lista de movimentos ordenada por data desc
class ExtractoView extends StatelessWidget {
  const ExtractoView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExtractoController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Minhas Taxas de Condomínio'),
        backgroundColor: AppColors.bgDark,
      ),
      body: Obx(() {
        if (controller.isLoadingSaldo.value && controller.saldo.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erro.value != null && controller.saldo.value == null) {
          return _ErroExtracto(
            mensagem: controller.erro.value!,
            onRetry: controller.carregarTudo,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.carregarTudo,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.saldo.value != null)
                _SaldoHeader(saldo: controller.saldo.value!),
              const SizedBox(height: 12),
              if (controller.saldo.value != null &&
                  !controller.saldo.value!.estaEmDia)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(() => const PagamentoFormView()),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Pagar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => Get.to(() => const MeusPagamentosView()),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Histórico'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                )
              else if (controller.saldo.value != null)
                Center(
                  child: TextButton.icon(
                    onPressed: () => Get.to(() => const MeusPagamentosView()),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: const Text('Ver pagamentos anteriores'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (controller.saldo.value != null &&
                  controller.saldo.value!.porTipo.isNotEmpty)
                _DecomposicaoTipos(saldo: controller.saldo.value!),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Movimentos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (controller.movimentos.isEmpty &&
                  !controller.isLoadingMovimentos.value)
                const _VazioMovimentos()
              else
                ...controller.movimentos.map((m) => _MovimentoCard(movimento: m)),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }
}

/// Header — saldo total com gradient
class _SaldoHeader extends StatelessWidget {
  const _SaldoHeader({required this.saldo});
  final ExtractoSaldo saldo;

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(
      locale: 'pt_PT',
      symbol: 'Kz',
      decimalDigits: 2,
    );

    final emDia = saldo.estaEmDia;
    final temAtraso = saldo.temAtraso;

    final gradient = emDia
        ? const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : temAtraso
            ? const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.brandGradient;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                emDia ? Icons.check_circle : Icons.account_balance_wallet,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                emDia ? 'Estás em dia' : 'Total em dívida',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatador.format(saldo.totalEmDivida),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (saldo.numeroLancamentosEmDivida > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${saldo.numeroLancamentosEmDivida} '
              '${saldo.numeroLancamentosEmDivida == 1 ? "lançamento" : "lançamentos"} em aberto',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
          if (temAtraso) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${formatador.format(saldo.totalEmAtraso)} em atraso',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Decomposição por tipo (quotas, multas, despesas extras)
class _DecomposicaoTipos extends StatelessWidget {
  const _DecomposicaoTipos({required this.saldo});
  final ExtractoSaldo saldo;

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(
      locale: 'pt_PT',
      symbol: 'Kz',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Decomposição',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ...saldo.porTipo.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(_iconePorTipo(e.key), color: AppColors.cyan, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _labelPorTipo(e.key),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      formatador.format(e.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  IconData _iconePorTipo(String tipo) {
    switch (tipo) {
      case 'quota_base':
        return Icons.home_outlined;
      case 'fundo_reserva':
        return Icons.savings_outlined;
      case 'despesa_extra':
        return Icons.receipt_long_outlined;
      case 'multa':
        return Icons.warning_amber_outlined;
      case 'juros':
        return Icons.percent;
      default:
        return Icons.circle_outlined;
    }
  }

  String _labelPorTipo(String tipo) {
    switch (tipo) {
      case 'quota_base':
        return 'Taxas de Condomínio mensais';
      case 'fundo_reserva':
        return 'Fundo de reserva';
      case 'despesa_extra':
        return 'Despesas extras';
      case 'multa':
        return 'Multas';
      case 'juros':
        return 'Juros';
      case 'ajuste_credito':
        return 'Créditos';
      case 'ajuste_debito':
        return 'Ajustes';
      default:
        return tipo;
    }
  }
}

/// Card de movimento individual
class _MovimentoCard extends StatelessWidget {
  const _MovimentoCard({required this.movimento});
  final Movimento movimento;

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(
      locale: 'pt_PT',
      symbol: 'Kz',
      decimalDigits: 2,
    );
    final formatadorData = DateFormat('d MMM yyyy', 'pt_PT');

    final isCredito = movimento.isCredito;
    final foiCancelado = movimento.foiCancelado;

    final corValor = foiCancelado
        ? AppColors.textMuted
        : isCredito
            ? const Color(0xFF10B981)
            : Colors.white;

    final corIcon = foiCancelado
        ? AppColors.textMuted
        : isCredito
            ? const Color(0xFF10B981)
            : movimento.emAtraso
                ? const Color(0xFFEF4444)
                : AppColors.cyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foiCancelado
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: corIcon.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconeMovimento(), color: corIcon, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimento.descricao,
                  style: TextStyle(
                    color: foiCancelado ? AppColors.textMuted : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: foiCancelado
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      formatadorData.format(movimento.data),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (movimento.fraccao?.identificador != null) ...[
                      const SizedBox(width: 6),
                      const Text('·',
                          style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Text(
                        'Imóvel ${movimento.fraccao!.identificador}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (movimento.emAtraso && !foiCancelado) ...[
                      const SizedBox(width: 6),
                      const Text('·',
                          style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      const Text(
                        'em atraso',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredito ? "+" : "-"}${formatador.format(movimento.valor)}',
            style: TextStyle(
              color: corValor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration:
                  foiCancelado ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconeMovimento() {
    if (movimento.isPagamento) return Icons.check_circle_outline;
    switch (movimento.tipo) {
      case 'quota_base':
        return Icons.home_outlined;
      case 'fundo_reserva':
        return Icons.savings_outlined;
      case 'despesa_extra':
        return Icons.receipt_long_outlined;
      case 'multa':
        return Icons.warning_amber_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

class _VazioMovimentos extends StatelessWidget {
  const _VazioMovimentos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text(
            'Sem movimentos.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Estado de erro do extracto (quando nem o saldo carregou), com retry.
class _ErroExtracto extends StatelessWidget {
  final String mensagem;
  final Future<void> Function() onRetry;

  const _ErroExtracto({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 44),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar de novo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
