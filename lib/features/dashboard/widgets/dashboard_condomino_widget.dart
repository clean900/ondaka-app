import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../assembleias/views/minhas_assembleias_view.dart';
import '../../avisos/views/meus_avisos_view.dart';
import '../../pre_aprovacoes/repositories/pre_aprovacao_repository.dart';
import '../../pre_aprovacoes/views/historico_visitas_view.dart';
import '../../tickets/views/meus_tickets_view.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_data.dart';

/// Dashboard inline para condómino — mostra-se na home.
/// 4 widgets de overview + lista de próximas assembleias.
class DashboardCondominoWidget extends StatelessWidget {
  const DashboardCondominoWidget({super.key});

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

      if (data.tudoEmDia) {
        return _tudoEmDiaCard();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Grid 2x2 dos counters ===
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.event_outlined,
                  label: 'Assembleias',
                  value: data.assembleiasProximas.length.toString(),
                  cor: AppColors.info,
                  onTap: () => Get.to(() => const MinhasAssembleiasView()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.notifications_outlined,
                  label: 'Avisos não lidos',
                  value: data.avisosNaoLidos.toString(),
                  cor: data.avisosNaoLidos > 0
                      ? AppColors.warning
                      : AppColors.surfaceHi,
                  onTap: () => Get.to(() => const MeusAvisosView()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Tickets abertos',
                  value: data.ticketsAbertos.toString(),
                  cor: AppColors.cyan,
                  onTap: () => Get.to(() => const MeusTicketsView()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.people_outline,
                  label: 'Visitas pendentes',
                  value: data.visitasProximas.toString(),
                  cor: AppColors.purple,
                  onTap: () => Get.to(() => HistoricoVisitasView(fetch: PreAprovacaoRepository().historicoVisitas)),
                ),
              ),
            ],
          ),

          // === Lista próximas assembleias ===
          if (data.assembleiasProximas.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Próximas reuniões',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...data.assembleiasProximas.map(
              (a) => _ProximaAssembleiaCard(
                assembleia: a,
                onTap: () => Get.to(() => const MinhasAssembleiasView()),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _tudoEmDiaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tudo em dia',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sem assembleias, avisos ou tickets pendentes.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color cor;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: cor,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProximaAssembleiaCard extends StatelessWidget {
  final ProximaAssembleia assembleia;
  final VoidCallback onTap;

  const _ProximaAssembleiaCard({required this.assembleia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  assembleia.modo == 'virtual'
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  color: AppColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assembleia.titulo,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmtData(assembleia.dataAgendada),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textFaint,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} às $hora:$min';
  }
}
