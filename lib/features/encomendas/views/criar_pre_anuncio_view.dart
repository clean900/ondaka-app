import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/criar_pre_anuncio_controller.dart';
import '../controllers/minhas_encomendas_controller.dart';

class CriarPreAnuncioView extends StatelessWidget {
  const CriarPreAnuncioView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CriarPreAnuncioController(), tag: 'criarPreAnuncio');

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Pré-anunciar encomenda'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Avisa a portaria que vais receber uma encomenda.',
                      style: TextStyle(color: AppColors.cyanSoft, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Descrição
            const _Label('Descrição da encomenda *'),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ex: Caixa Amazon, encomenda DHL...',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              maxLength: 500,
              onChanged: (v) => controller.descricao.value = v,
            ),

            const SizedBox(height: 8),

            // Remetente
            const _Label('Remetente (opcional)'),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ex: Loja XYZ, DHL Express...',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              maxLength: 255,
              onChanged: (v) => controller.remetente.value = v,
            ),

            const SizedBox(height: 16),

            // Janela esperada de chegada (opcional, simplificado por agora)
            Text(
              'Janela esperada de chegada (opcional)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _DatePicker(
                        label: 'A partir de',
                        value: controller.janelaInicio.value,
                        onChanged: (d) => controller.janelaInicio.value = d,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DatePicker(
                        label: 'Até',
                        value: controller.janelaFim.value,
                        onChanged: (d) => controller.janelaFim.value = d,
                      ),
                    ),
                  ],
                )),

            const SizedBox(height: 24),

            // Erro
            Obx(() {
              if (controller.erro.value == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(controller.erro.value!,
                          style: TextStyle(color: AppColors.dangerSoft)),
                    ),
                  ],
                ),
              );
            }),

            // Botão submeter
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.podeSubmeter
                        ? () => _submeter(controller)
                        : null,
                    icon: controller.isSubmetendo.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(controller.isSubmetendo.value
                        ? 'A enviar...'
                        : 'Pré-anunciar'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.black,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _submeter(CriarPreAnuncioController controller) async {
    final encomenda = await controller.submeter();
    if (encomenda != null) {
      // Recarregar a lista no shell
      if (Get.isRegistered<MinhasEncomendasController>()) {
        Get.find<MinhasEncomendasController>().carregar();
      }
      controller.reset();
      Get.back();
      Get.snackbar(
        'Pré-anúncio criado',
        'A portaria foi notificada.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: now.add(const Duration(days: 90)),
        );
        if (picked != null) onChanged(picked);
      },
      onLongPress: value != null ? () => onChanged(null) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceHi),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null
                    ? '${value!.day}/${value!.month}'
                    : label,
                style: TextStyle(
                  color: value != null ? Colors.white : AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
