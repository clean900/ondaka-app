import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checklist_controller.dart';
import '../../../app/theme/app_colors.dart';
import 'checklist_execucao_view.dart';

class ChecklistListaView extends StatelessWidget {
  const ChecklistListaView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChecklistController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Checklists'),
      ),
      body: Obx(() {
        if (c.aCarregar.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.erro.value != null) {
          return Center(child: Text(c.erro.value!, style: const TextStyle(color: AppColors.textMuted)));
        }
        if (c.modelos.isEmpty) {
          return const Center(
            child: Text('Nenhuma checklist disponível.', style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return RefreshIndicator(
          onRefresh: c.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: c.modelos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final m = c.modelos[i];
              return InkWell(
                onTap: () => Get.to(() => ChecklistExecucaoView(modelo: m)),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.nome, style: const TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${m.tipo} · ${m.itens.length} itens', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textFaint),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
