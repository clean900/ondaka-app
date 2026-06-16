import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/documentos_controller.dart';
import '../models/documento.dart';

class DocumentosView extends StatelessWidget {
  const DocumentosView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DocumentosController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Documentos'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.documentos.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (c.documentos.isEmpty) {
          return RefreshIndicator(
            onRefresh: c.carregar,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ainda não há documentos partilhados pela gestão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: c.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: c.documentos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _DocCard(documento: c.documentos[i], controller: c),
          ),
        );
      }),
    );
  }
}

class _DocCard extends StatelessWidget {
  final Documento documento;
  final DocumentosController controller;
  const _DocCard({required this.documento, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => controller.abrir(documento),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.cyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(documento.nome,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                  const SizedBox(height: 2),
                  Text(
                    documento.descricao?.isNotEmpty == true
                        ? '${documento.categoriaLabel} · ${documento.descricao}'
                        : documento.categoriaLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
