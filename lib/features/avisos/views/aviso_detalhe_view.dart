import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/aviso_detalhe_controller.dart';
import '../models/aviso.dart';

class AvisoDetalheView extends StatefulWidget {
  final int avisoId;
  const AvisoDetalheView({super.key, required this.avisoId});

  @override
  State<AvisoDetalheView> createState() => _AvisoDetalheViewState();
}

class _AvisoDetalheViewState extends State<AvisoDetalheView> {
  late final AvisoDetalheController controller;
  final _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      AvisoDetalheController(avisoId: widget.avisoId),
      tag: 'aviso-${widget.avisoId}',
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    Get.delete<AvisoDetalheController>(tag: 'aviso-${widget.avisoId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.aviso.value != null
            ? 'Aviso #${controller.aviso.value!.id}'
            : 'Aviso')),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.aviso.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null) {
          return _erroState();
        }
        final a = controller.aviso.value;
        if (a == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _cabecalho(a),
              const SizedBox(height: 16),
              _descricao(a),
              if (a.anexos.isNotEmpty) ...[
                const SizedBox(height: 16),
                _anexos(a),
              ],
              if (a.requerConfirmacao && !a.jaConfirmado) ...[
                const SizedBox(height: 16),
                _botaoConfirmar(),
              ],
              const SizedBox(height: 16),
              _thread(a),
              if (a.permiteComentarios) ...[
                const SizedBox(height: 12),
                _formComentario(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _erroState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(controller.erro.value!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(Aviso a) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(a.categoria.icon,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                _badge(a.prioridade.label, a.prioridade.cor),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.categoria.label,
                      style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(a.titulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person,
                    size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(a.autorNome ?? 'Admin',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.access_time,
                    size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(_fmtDateHour(a.publicadoEm ?? a.createdAt),
                    style: theme.textTheme.bodySmall),
              ],
            ),
            if (a.jaConfirmado) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text('Confirmaste a leitura',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _descricao(Aviso a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          a.descricao.replaceAll(RegExp(r'<[^>]*>'), ''),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _anexos(Aviso a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anexos (${a.anexos.length})',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            ...a.anexos.map((anexo) => _anexoTile(anexo)),
          ],
        ),
      ),
    );
  }

  Widget _anexoTile(AvisoAnexo anexo) {
    final theme = Theme.of(context);
    final url = 'https://ondaka.ao/storage/${anexo.path}';
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              anexo.eImagem
                  ? Icons.image
                  : (anexo.ePdf ? Icons.picture_as_pdf : Icons.insert_drive_file),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(anexo.nomeOriginal,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(_fmtBytes(anexo.tamanhoBytes),
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.download, size: 18, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _botaoConfirmar() {
    return Obx(() => FilledButton.icon(
          onPressed:
              controller.isConfirmando.value ? null : controller.confirmarLeitura,
          icon: controller.isConfirmando.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle),
          label: Text(controller.isConfirmando.value
              ? 'A confirmar...'
              : 'Confirmar leitura'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(52),
          ),
        ));
  }

  Widget _thread(Aviso a) {
    final theme = Theme.of(context);
    final comentariosVisiveis = a.comentarios;
    if (comentariosVisiveis.isEmpty && !a.permiteComentarios) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discussão (${comentariosVisiveis.length})',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            if (comentariosVisiveis.isEmpty)
              Text(
                'Sem comentários ainda. Sê o primeiro!',
                style: theme.textTheme.bodySmall,
              )
            else
              ...comentariosVisiveis.map(_comentarioCard),
          ],
        ),
      ),
    );
  }

  Widget _comentarioCard(AvisoComentario c) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.destaque
            ? Colors.amber.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: c.destaque
            ? Border.all(color: Colors.amber.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.userName ?? 'Anónimo',
                  style: theme.textTheme.labelMedium),
              if (c.destaque) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, size: 12, color: Colors.amber),
              ],
              const Spacer(),
              Text(_fmtDateHour(c.createdAt),
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.mensagem, style: theme.textTheme.bodyMedium),
          if (c.respostas.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...c.respostas.map((r) => Container(
                  margin: const EdgeInsets.only(left: 16, top: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(r.userName ?? 'Anónimo',
                              style: theme.textTheme.labelSmall),
                          const Spacer(),
                          Text(_fmtDateHour(r.createdAt),
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(r.mensagem, style: theme.textTheme.bodySmall),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _formComentario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _comentarioController,
              decoration: const InputDecoration(
                hintText: 'Escreve um comentário ou pergunta...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 5000,
            ),
            const SizedBox(height: 8),
            Obx(() => FilledButton.icon(
                  onPressed: controller.isComentando.value
                      ? null
                      : () async {
                          final ok = await controller
                              .comentar(_comentarioController.text);
                          if (ok) _comentarioController.clear();
                        },
                  icon: controller.isComentando.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(controller.isComentando.value
                      ? 'A enviar...'
                      : 'Enviar'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }

  String _fmtDateHour(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$min';
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
