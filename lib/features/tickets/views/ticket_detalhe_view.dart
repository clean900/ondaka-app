import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ticket_detalhe_controller.dart';
import '../models/ticket.dart';

class TicketDetalheView extends StatefulWidget {
  final int ticketId;
  const TicketDetalheView({super.key, required this.ticketId});

  @override
  State<TicketDetalheView> createState() => _TicketDetalheViewState();
}

class _TicketDetalheViewState extends State<TicketDetalheView> {
  late final TicketDetalheController controller;
  final _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      TicketDetalheController(ticketId: widget.ticketId),
      tag: 'ticket-${widget.ticketId}',
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    Get.delete<TicketDetalheController>(tag: 'ticket-${widget.ticketId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.ticket.value != null
            ? 'Ticket #${controller.ticket.value!.id}'
            : 'Ticket')),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.ticket.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null) {
          return _erroState();
        }
        final ticket = controller.ticket.value;
        if (ticket == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _cabecalho(ticket),
              const SizedBox(height: 16),
              _dadosBasicos(ticket),
              if (ticket.fotos.isNotEmpty) ...[
                const SizedBox(height: 16),
                _fotos(ticket),
              ],
              const SizedBox(height: 16),
              _thread(ticket),
              const SizedBox(height: 12),
              _formComentario(),
              if (ticket.estado.estaAberto) ...[
                const SizedBox(height: 24),
                _botaoCancelar(),
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

  Widget _cabecalho(Ticket t) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _badge(t.estado.label, t.estado.cor),
                const SizedBox(width: 6),
                _badgePequeno(t.prioridade.label, t.prioridade.cor),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.categoria.icon, size: 12),
                      const SizedBox(width: 4),
                      Text(t.categoria.label,
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(t.titulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(t.descricao, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _dadosBasicos(Ticket t) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaInfo(Icons.person, 'Aberto por', t.abertoPorNome ?? 'N/A'),
            if (t.fraccaoIdentificador != null)
              _linhaInfo(Icons.home, 'Fracção', t.fraccaoIdentificador!),
            _linhaInfo(Icons.access_time, 'Criado em', _fmtDateHour(t.createdAt)),
            if (t.atribuidoANome != null)
              _linhaInfo(
                  Icons.assignment_ind, 'Atribuído a', t.atribuidoANome!),
            if (t.resolvidoEm != null)
              _linhaInfo(Icons.check_circle, 'Resolvido em',
                  _fmtDateHour(t.resolvidoEm!)),
            if (t.fechadoEm != null)
              _linhaInfo(
                  Icons.lock, 'Fechado em', _fmtDateHour(t.fechadoEm!)),
            const SizedBox(height: 8),
            Text('Estatísticas', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.comment, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text('${t.comentarios.length} comentários',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.image, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text('${t.fotos.length} fotos',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotos(Ticket t) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: t.fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final foto = t.fotos[i];
          return Container(
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              'https://ondaka.ao/storage/${foto.path}',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.image_not_supported),
            ),
          );
        },
      ),
    );
  }

  Widget _thread(Ticket t) {
    final theme = Theme.of(context);
    if (t.comentarios.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sem comentários ainda.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comentários (${t.comentarios.length})',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            ...t.comentarios
                .where((c) => c.publico)
                .map((c) => _comentario(c)),
          ],
        ),
      ),
    );
  }

  Widget _comentario(TicketComentario c) {
    final theme = Theme.of(context);
    final eMudanca = c.eMudancaEstado;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: eMudanca
            ? Colors.amber.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: eMudanca
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
              const Spacer(),
              Text(_fmtDateHour(c.createdAt),
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.mensagem, style: theme.textTheme.bodyMedium),
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
                hintText: 'Escreve um comentário...',
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
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(controller.isComentando.value
                      ? 'A enviar...'
                      : 'Enviar comentário'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _botaoCancelar() {
    return Obx(() => OutlinedButton.icon(
          onPressed: controller.isCancelando.value
              ? null
              : _confirmarCancelar,
          icon: controller.isCancelando.value
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cancel_outlined),
          label: Text(controller.isCancelando.value
              ? 'A cancelar...'
              : 'Cancelar este ticket'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(48),
          ),
        ));
  }

  void _confirmarCancelar() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar ticket?'),
        content: const Text(
            'Esta acção não pode ser desfeita. O ticket será marcado como cancelado.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Não'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.cancelar();
            },
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _linhaInfo(IconData icon, String label, String valor) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text('$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              )),
          Expanded(
            child: Text(valor,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
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

  Widget _badgePequeno(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w500)),
    );
  }

  String _fmtDateHour(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes ${dt.year} $hora:$min';
  }
}
