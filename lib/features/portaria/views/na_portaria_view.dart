import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../encomendas/models/encomenda.dart';
import '../controllers/portaria_encomendas_controller.dart';
import 'entregar_encomenda_dialog.dart';

/// Sub-tab "Portaria" — encomendas que chegaram e aguardam levantamento.
///
/// Permite entregar ao titular ou a uma pessoa autorizada da fracção.
class NaPortariaView extends StatelessWidget {
  const NaPortariaView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PortariaEncomendasController>();

    return Obx(() {
      if (controller.isLoadingPortaria.value && controller.naPortaria.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.naPortaria.isEmpty) {
        return _vazio();
      }

      return RefreshIndicator(
        onRefresh: controller.carregarNaPortaria,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: controller.naPortaria.length,
          itemBuilder: (context, index) {
            final e = controller.naPortaria[index];
            return _NaPortariaCard(
              encomenda: e,
              onEntregar: () => _abrirDialogEntregar(context, e, controller),
            );
          },
        ),
      );
    });
  }

  Future<void> _abrirDialogEntregar(
    BuildContext context,
    Encomenda e,
    PortariaEncomendasController controller,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => EntregarEncomendaDialog(encomenda: e),
    );
  }

  Widget _vazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text(
            'Sem encomendas em portaria.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quando uma encomenda chega, aparece aqui para entregar.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NaPortariaCard extends StatelessWidget {
  const _NaPortariaCard({
    required this.encomenda,
    required this.onEntregar,
  });

  final Encomenda encomenda;
  final VoidCallback onEntregar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2,
                      color: AppColors.cyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        encomenda.descricao,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
            if (encomenda.remetente != null && encomenda.remetente!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _info(Icons.local_shipping_outlined, encomenda.remetente!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEntregar,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Entregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: const Color(0xFF001218),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
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
}
