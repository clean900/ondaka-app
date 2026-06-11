import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../models/acordo.dart';
import 'acordos_view.dart';
import '../../extracto/views/extracto_view.dart';

/// Ecrã mostrado quando o condómino tenta uma acção bloqueada por dívida (403).
class AcessoLimitadoView extends StatelessWidget {
  final LimitacaoInfo? info;
  const AcessoLimitadoView({super.key, this.info});

  String _kz(double v) => NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz ', decimalDigits: 2).format(v);

  @override
  Widget build(BuildContext context) {
    final total = info?.totalEmDivida ?? 0;
    final vencidas = info?.taxasVencidas ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Acesso limitado'),
        backgroundColor: AppColors.bgDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock, color: AppColors.warning, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Acesso temporariamente limitado',
                style: TextStyle(color: AppColors.textMain, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
              'Verificámos que existem taxas de condomínio em atraso associadas ao seu imóvel. '
              'Para regularizar a situação, algumas funcionalidades estão temporariamente limitadas.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Continua a ter acesso ao seu extracto, aos pagamentos e à proposta de acordo. '
              'O alerta de emergência (SOS) permanece sempre disponível.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            if (total > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Valor em atraso', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text(_kz(total), style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 18)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Taxas vencidas', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text('$vencidas', style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 18)),
                    ]),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Sabemos que podem surgir dificuldades. Pode propor um plano de pagamento em prestações '
              'adaptado à sua situação — a gestão analisará a sua proposta.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const AcordosView()),
                icon: const Icon(Icons.handshake),
                label: const Text('Propor acordo de pagamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: AppColors.bgDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => const ExtractoView()),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Ver as minhas taxas e pagar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: const BorderSide(color: AppColors.cyan),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMain,
                  side: const BorderSide(color: AppColors.borderHi),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
