import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/despesa_comissao_controller.dart';
import '../models/despesa_pendente.dart';

class DespesasComissaoView extends StatelessWidget {
  const DespesasComissaoView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DespesaComissaoController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Despesas da Comissão'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.despesas.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (c.erro.value != null && c.despesas.isEmpty) {
          return _Centro(texto: c.erro.value!, onRetry: c.carregar);
        }
        if (c.despesas.isEmpty) {
          return _Centro(texto: 'Sem despesas pendentes de aprovação.', onRetry: c.carregar);
        }
        return RefreshIndicator(
          onRefresh: c.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: c.despesas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _DespesaCard(despesa: c.despesas[i], controller: c),
          ),
        );
      }),
    );
  }
}

class _Centro extends StatelessWidget {
  final String texto;
  final VoidCallback onRetry;
  const _Centro({required this.texto, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Recarregar')),
        ],
      ),
    );
  }
}

class _DespesaCard extends StatelessWidget {
  final DespesaPendente despesa;
  final DespesaComissaoController controller;
  const _DespesaCard({required this.despesa, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  despesa.descricao ?? 'Despesa',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${despesa.valor.toStringAsFixed(0)} Kz',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.cyan),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              if (despesa.fornecedor != null) _meta(Icons.store_outlined, despesa.fornecedor!),
              if (despesa.categoria != null) _meta(Icons.label_outline, despesa.categoria!),
              if (despesa.condominio != null) _meta(Icons.apartment_outlined, despesa.condominio!),
              if (despesa.dataDespesa != null) _meta(Icons.event_outlined, despesa.dataDespesa!),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final aProcessar = controller.aProcessar.contains(despesa.id);
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: aProcessar ? null : () => controller.recusar(despesa),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: aProcessar ? null : () => controller.aprovar(despesa),
                    icon: aProcessar
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Aprovar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textFaint),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
