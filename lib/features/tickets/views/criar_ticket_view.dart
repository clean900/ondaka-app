import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/criar_ticket_controller.dart';
import '../models/ticket.dart';

/// Form para criar um novo ticket (condomino).
class CriarTicketView extends StatefulWidget {
  const CriarTicketView({super.key});

  @override
  State<CriarTicketView> createState() => _CriarTicketViewState();
}

class _CriarTicketViewState extends State<CriarTicketView> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  late final CriarTicketController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CriarTicketController());
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo ticket')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ex: Torneira a pingar na cozinha',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Mínimo 5 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                hintText: 'Descreve em detalhe o que aconteceu...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 5000,
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Mínimo 10 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Categoria
            Text('Categoria *', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TicketCategoria.values.map((cat) {
                    final selected = controller.categoria.value == cat;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 14),
                          const SizedBox(width: 4),
                          Text(cat.label),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) => controller.categoria.value = cat,
                    );
                  }).toList(),
                )),
            const SizedBox(height: 16),

            // Prioridade
            Text('Prioridade *', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Obx(() => SegmentedButton<TicketPrioridade>(
                  segments: TicketPrioridade.values
                      .map((p) => ButtonSegment(
                            value: p,
                            label: Text(p.label),
                          ))
                      .toList(),
                  selected: {controller.prioridade.value},
                  onSelectionChanged: (s) =>
                      controller.prioridade.value = s.first,
                )),
            const SizedBox(height: 16),

            // Fotos
            Row(
              children: [
                Text('Fotos (opcional)',
                    style: theme.textTheme.labelLarge),
                const Spacer(),
                Obx(() => Text(
                      '${controller.fotos.length}/5',
                      style: theme.textTheme.bodySmall,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...controller.fotos.asMap().entries.map((e) {
                      return _PreviewFoto(
                        file: e.value,
                        onRemove: () => controller.removerFoto(e.key),
                      );
                    }),
                    if (controller.fotos.length < 5)
                      _AddFotoButton(onTap: _mostrarSelectorFonte),
                  ],
                )),
            const SizedBox(height: 24),

            Obx(() => FilledButton.icon(
                  onPressed:
                      controller.isSubmitting.value ? null : _submeter,
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(controller.isSubmitting.value
                      ? 'A criar...'
                      : 'Criar ticket'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorFonte() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmara'),
              onTap: () {
                Get.back();
                controller.adicionarFoto(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Get.back();
                controller.adicionarFoto(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;


    // Por enquanto, hardcoded condominio_id=2 (Paparazzi) para teste.
    // Em iteração futura: dropdown de fracções do condomino.
    final id = await controller.submeter(
      condominioId: 2,
      fraccaoId: 68,
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
    );


    if (id != null && mounted) {
      Get.back(result: true);
    }
  }
}

class _PreviewFoto extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _PreviewFoto({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddFotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Icon(Icons.add_a_photo,
            color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
