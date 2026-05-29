import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_chatbot_faq_controller.dart';
import '../models/chatbot_faq_admin.dart';
import '../widgets/faq_list_tile.dart';
import 'admin_chatbot_faq_form_page.dart';

class AdminChatbotFaqsPage extends StatelessWidget {
  const AdminChatbotFaqsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminChatbotFaqController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs do Chatbot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.carregar,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.faqs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null && controller.faqs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    controller.error.value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: controller.carregar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (controller.faqs.isEmpty) {
          return _emptyState(context);
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'FAQs específicas deste condomínio. Aparecem no Chatbot dos condóminos.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: controller.faqs.length,
                  buildDefaultDragHandles: false,
                  onReorder: controller.reordenar,
                  itemBuilder: (context, index) {
                    final faq = controller.faqs[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(faq.id),
                      index: index,
                      child: FaqListTile(
                        faq: faq,
                        onToggle: () => controller.toggle(faq),
                        onEdit: () => _abrirFormulario(context, faq: faq),
                        onDelete: () => _confirmarEliminar(context, controller, faq),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova FAQ'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Sem FAQs ainda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Cria a primeira FAQ para os condóminos verem no Chatbot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add),
              label: const Text('Criar primeira FAQ'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {ChatbotFaqAdmin? faq}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminChatbotFaqFormPage(faq: faq),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    AdminChatbotFaqController controller,
    ChatbotFaqAdmin faq,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar FAQ?'),
        content: Text(
          'Vais eliminar:\n\n"${faq.pergunta.length > 80 ? '${faq.pergunta.substring(0, 80)}...' : faq.pergunta}"\n\nEsta acção não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      final sucesso = await controller.eliminar(faq);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sucesso ? 'FAQ eliminada.' : 'Erro ao eliminar.'),
          backgroundColor: sucesso ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
