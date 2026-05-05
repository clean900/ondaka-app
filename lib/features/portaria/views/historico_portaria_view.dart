import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../encomendas/models/encomenda.dart';
import '../controllers/portaria_encomendas_controller.dart';

/// Sub-tab "Histórico" do shell de portaria.
///
/// Lista as últimas 50 encomendas que ESTE guarda específico entregou.
/// Filtrado por entregue_por_user_id no backend.
class HistoricoPortariaView extends StatelessWidget {
  const HistoricoPortariaView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PortariaEncomendasController>();

    return Obx(() {
      if (controller.isLoadingHistorico.value && controller.historico.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.historico.isEmpty) {
        return _vazio();
      }

      return RefreshIndicator(
        onRefresh: controller.carregarHistorico,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: controller.historico.length,
          itemBuilder: (context, index) {
            final e = controller.historico[index];
            return _HistoricoCard(encomenda: e);
          },
        ),
      );
    });
  }

  Widget _vazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history,
              size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text(
            'Sem histórico de entregas.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'As encomendas que entregaste aparecem aqui.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricoCard extends StatelessWidget {
  const _HistoricoCard({required this.encomenda});
  final Encomenda encomenda;

  @override
  Widget build(BuildContext context) {
    final dataLevantamento = encomenda.levantadaEm != null
        ? _formatarData(encomenda.levantadaEm!)
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.cyan, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      encomenda.descricao,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (encomenda.fraccao != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Fracção ${encomenda.fraccao!.identificador}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info(
                  Icons.person_outline,
                  encomenda.levantadaPor ?? '—',
                ),
                const SizedBox(height: 4),
                _info(Icons.access_time, dataLevantamento),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final ano = d.year;
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$min';
  }
}
