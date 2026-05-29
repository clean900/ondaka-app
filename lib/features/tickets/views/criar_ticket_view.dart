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
      appBar: AppBar(title: const Text('Novo Pedido de Intervenção')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Condominio dropdown
            Obx(() {
              if (controller.isCarregandoFraccoes.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (controller.condominios.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nao tem fraccoes activas em nenhum condominio.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                );
              }
              // Se so ha 1 condominio, esconder dropdown (ja auto-seleccionado)
              if (controller.condominios.length == 1) {
                return const SizedBox.shrink();
              }
              return DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Condominio *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apartment),
                ),
                initialValue: controller.condominioSelecionado.value?.id,
                items: controller.condominios
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nome, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  controller.condominioSelecionado.value =
                      controller.condominios.firstWhere((c) => c.id == id);
                  // Reset fraccao quando muda condominio
                  controller.fraccaoSelecionada.value = null;
                  // Auto-seleccionar fraccao se so houver 1
                  final fracs = controller.fraccoesDoCondominio;
                  if (fracs.length == 1) {
                    controller.fraccaoSelecionada.value = fracs.first;
                  }
                },
                validator: (v) => v == null ? 'Obrigatorio' : null,
              );
            }),
            Obx(() => controller.condominios.length > 1
                ? const SizedBox(height: 12)
                : const SizedBox.shrink()),

            // Imovel (fraccao) dropdown
            Obx(() {
              final fracs = controller.fraccoesDoCondominio;
              if (controller.condominioSelecionado.value == null) {
                return const SizedBox.shrink();
              }
              if (fracs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nao tem imoveis activos neste condominio.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                );
              }
              // Se so ha 1 fraccao, esconder dropdown (ja auto-seleccionado)
              if (fracs.length == 1) {
                return const SizedBox.shrink();
              }
              return DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Imovel *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                initialValue: controller.fraccaoSelecionada.value?.id,
                items: fracs
                    .map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.labelCompleto,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  controller.fraccaoSelecionada.value =
                      fracs.firstWhere((f) => f.id == id);
                },
                validator: (v) => v == null ? 'Obrigatorio' : null,
              );
            }),
            Obx(() => controller.fraccoesDoCondominio.length > 1
                ? const SizedBox(height: 12)
                : const SizedBox.shrink()),

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

            // Tipo: Particular ou Publico
            Text('Tipo *', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Particular: visivel a si e gestao. Publico: visivel a todos os condominos (podem apoiar).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => SegmentedButton<TicketTipo>(
                  segments: TicketTipo.values
                      .map((t) => ButtonSegment(
                            value: t,
                            icon: Icon(t.icon, size: 16),
                            label: Text(t.label),
                          ))
                      .toList(),
                  selected: {controller.tipo.value},
                  onSelectionChanged: (s) {
                    controller.tipo.value = s.first;
                    // Limpa categoria selecionada quando muda o tipo
                    controller.categoriaSelecionada.value = null;
                  },
                )),
            const SizedBox(height: 16),

            // Categoria dinamica (filtrada pelo tipo)
            Text('Categoria *', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isCarregandoCategorias.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final lista = controller.categoriasDoTipo;
              if (lista.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Sem categorias disponiveis para este tipo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lista.map((cat) {
                  final selected =
                      controller.categoriaSelecionada.value?.id == cat.id;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.materialIcon, size: 14),
                        const SizedBox(width: 4),
                        Text(cat.nome),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        controller.categoriaSelecionada.value = cat,
                  );
                }).toList(),
              );
            }),
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
                      : 'Criar Pedido'),
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


    // Validar selecao de condominio e fraccao
    final cond = controller.condominioSelecionado.value;
    final frac = controller.fraccaoSelecionada.value;
    if (cond == null) {
      Get.snackbar('Falta condominio', 'Seleccione um condominio.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (frac == null) {
      Get.snackbar('Falta imovel', 'Seleccione um imovel.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final id = await controller.submeter(
      condominioId: cond.id,
      fraccaoId: frac.id,
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
    );


    if (id != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop(true);
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
