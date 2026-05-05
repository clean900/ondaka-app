import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/minhas_encomendas_controller.dart';
import '../widgets/encomenda_card.dart';

class NaPortariaView extends StatelessWidget {
  const NaPortariaView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MinhasEncomendasController>();

    return Obx(() {
      if (controller.isLoading.value && controller.encomendas.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.naPortaria.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Nenhuma encomenda na portaria',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quando uma encomenda chegar à portaria do condomínio, ela aparece aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.carregar,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: controller.naPortaria.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final e = controller.naPortaria[index];
            return EncomendaCard(encomenda: e);
          },
        ),
      );
    });
  }
}
