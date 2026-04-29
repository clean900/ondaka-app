import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../assembleias/views/minhas_assembleias_view.dart';
import '../../avisos/views/meus_avisos_view.dart';
import '../../faqs/views/faqs_view.dart';
import '../../pre_aprovacoes/repositories/pre_aprovacao_repository.dart';
import '../../pre_aprovacoes/views/criar_pre_aprovacao_view.dart';
import '../../pre_aprovacoes/views/historico_visitas_view.dart';
import '../../tickets/views/meus_tickets_view.dart';
import '../controllers/dashboard_controller.dart';

/// Dashboard v3 — inspirado na versão web ONDAKA.
/// Quota anual + Histórico chart + KPIs 2x2 + Acções rápidas.
class DashboardV3Widget extends StatelessWidget {
  const DashboardV3Widget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Obx(() {
      if (controller.isLoading.value && controller.dashboard.value == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.erro.value != null && controller.dashboard.value == null) {
        return _erroState(controller);
      }

      final data = controller.dashboard.value;
      if (data == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardQuotaAnual(),
          const SizedBox(height: 14),
          const _CardHistoricoPagamentos(),
          const SizedBox(height: 14),
          _GridKpis(
            reunioes: data.assembleiasProximas.length,
            avisos: data.avisosNaoLidos,
            tickets: data.ticketsAbertos,
            visitas: data.visitasProximas,
            proximaReuniaoLabel: data.assembleiasProximas.isNotEmpty
                ? _fmtProximaReuniao(data.assembleiasProximas.first.dataAgendada)
                : 'sem agenda',
          ),
          const SizedBox(height: 14),
          const _SectionTitle('Acções rápidas'),
          const SizedBox(height: 8),
          _AccoesRapidas(),
        ],
      );
    });
  }

  String _fmtProximaReuniao(DateTime dt) {
    const meses = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    return 'próxima ${dt.day.toString().padLeft(2, '0')} ${meses[dt.month]}';
  }

  Widget _erroState(DashboardController c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 28),
          const SizedBox(height: 8),
          Text(
            c.erro.value!,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: c.carregar,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CARDS
// =============================================================================

class _CardQuotaAnual extends StatelessWidget {
  const _CardQuotaAnual();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'QUOTA ANUAL 2026',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '120.000 Kz',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'PAGO',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '75.000',
                    style: TextStyle(
                      color: AppColors.successSoft,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.62,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.cyan, AppColors.pink],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '62% pago · 30.000 Kz em atraso (2 meses)',
            style: TextStyle(color: AppColors.dangerSoft, fontSize: 11),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Get.snackbar(
                'Em breve',
                'Pagamento de quotas estará disponível com o módulo de Extracto Individual.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.surfaceHi,
                colorText: AppColors.textMain,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pagar agora →',
                style: TextStyle(
                  color: Color(0xFF001218),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHistoricoPagamentos extends StatelessWidget {
  const _CardHistoricoPagamentos();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Histórico de pagamentos',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '↗ 12.4%',
                style: TextStyle(
                  color: AppColors.successSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Últimos 6 meses',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _ChartLabel('Nov'),
              _ChartLabel('Dez'),
              _ChartLabel('Jan'),
              _ChartLabel('Fev'),
              _ChartLabel('Mar'),
              _ChartLabel('Abr'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final String texto;
  const _ChartLabel(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(color: AppColors.textFaint, fontSize: 10),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  // Pontos fake — y normalizado 0..1, sendo 0=topo e 1=base
  static const _pontos = [0.7, 0.65, 0.55, 0.45, 0.28, 0.12];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stepX = w / (_pontos.length - 1);

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < _pontos.length; i++) {
      final x = i * stepX;
      final y = _pontos[i] * h;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath
      ..lineTo(w, h)
      ..close();

    // Fill com gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.cyan.withValues(alpha: 0.25),
          AppColors.pink.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Linha gradient
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.cyan, AppColors.pink],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Ponto final destacado
    final dotPaint = Paint()..color = AppColors.pink;
    canvas.drawCircle(
      Offset(w, _pontos.last * h),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridKpis extends StatelessWidget {
  final int reunioes;
  final int avisos;
  final int tickets;
  final int visitas;
  final String proximaReuniaoLabel;

  const _GridKpis({
    required this.reunioes,
    required this.avisos,
    required this.tickets,
    required this.visitas,
    required this.proximaReuniaoLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.event_outlined,
                cor: AppColors.info,
                label: 'Reuniões',
                valor: reunioes.toString(),
                sublabel: proximaReuniaoLabel,
                onTap: () => Get.to(() => const MinhasAssembleiasView()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiCard(
                icon: Icons.notifications_outlined,
                cor: AppColors.warning,
                label: 'Avisos',
                valor: avisos.toString(),
                sublabel: avisos > 0 ? 'não lidos' : 'em dia',
                onTap: () => Get.to(() => const MeusAvisosView()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.confirmation_number_outlined,
                cor: AppColors.cyan,
                label: 'Tickets',
                valor: tickets.toString(),
                sublabel: tickets > 0 ? 'abertos' : 'sem pedidos',
                onTap: () => Get.to(() => const MeusTicketsView()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiCard(
                icon: Icons.people_outline,
                cor: AppColors.purple,
                label: 'Visitas',
                valor: visitas.toString(),
                sublabel: visitas > 0 ? 'pendentes' : 'sem agenda',
                onTap: () => Get.to(
                  () => HistoricoVisitasView(
                    fetch: PreAprovacaoRepository().historicoVisitas,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color cor;
  final String label;
  final String valor;
  final String sublabel;
  final VoidCallback onTap;

  const _KpiCard({
    required this.icon,
    required this.cor,
    required this.label,
    required this.valor,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: cor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(color: cor, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccoesRapidas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccaoBotao(
            icon: Icons.person_add_alt_1,
            label: 'Visitante',
            onTap: () => Get.to(() => const CriarPreAprovacaoView()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AccaoBotao(
            icon: Icons.confirmation_number_outlined,
            label: 'Ticket',
            onTap: () => Get.to(() => const MeusTicketsView()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AccaoBotao(
            icon: Icons.help_outline,
            label: 'FAQ',
            onTap: () => Get.to(() => const FaqsView()),
          ),
        ),
      ],
    );
  }
}

class _AccaoBotao extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccaoBotao({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.cyan, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String titulo;
  const _SectionTitle(this.titulo);

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
