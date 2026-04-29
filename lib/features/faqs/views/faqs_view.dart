import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/faqs_controller.dart';
import '../models/faq.dart';

class FaqsView extends StatelessWidget {
  const FaqsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FaqsController());

    return Scaffold(
      appBar: AppBar(title: const Text('Perguntas frequentes')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null) {
          return _erroState(context, controller);
        }

        return Column(
          children: [
            _searchBar(context, controller),
            Expanded(
              child: controller.faqs.isEmpty
                  ? _emptyState(context, controller)
                  : RefreshIndicator(
                      onRefresh: controller.carregar,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: controller.faqs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final f = controller.faqs[i];
                          return _FaqCard(
                            faq: f,
                            controller: controller,
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _searchBar(BuildContext context, FaqsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        onChanged: c.atualizarQuery,
        decoration: InputDecoration(
          hintText: 'Pesquisar...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => c.query.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: c.limparQuery,
                )
              : const SizedBox.shrink()),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, FaqsController c) {
    final theme = Theme.of(context);
    final pesquisando = c.pesquisando;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pesquisando ? Icons.search_off : Icons.help_outline,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              pesquisando
                  ? 'Sem resultados para "${c.query.value}".'
                  : 'Sem perguntas frequentes.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              pesquisando
                  ? 'Tenta outra palavra-chave.'
                  : 'Quando a administração publicar FAQs, aparecem aqui.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _erroState(BuildContext context, FaqsController c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(c.erro.value!),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: c.carregar,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final Faq faq;
  final FaqsController controller;

  const _FaqCard({
    required this.faq,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => controller.alternarExpansao(faq.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final expandida = controller.estaExpandida(faq.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        faq.categoriaLabel,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      expandida
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.outline,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  faq.pergunta,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (expandida) ...[
                  const SizedBox(height: 12),
                  Text(
                    faq.resposta,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}
