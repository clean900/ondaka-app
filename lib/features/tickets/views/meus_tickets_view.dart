import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/meus_tickets_controller.dart';
import '../models/ticket.dart';
import 'criar_ticket_view.dart';
import 'ticket_detalhe_view.dart';

class MeusTicketsView extends StatelessWidget {
  const MeusTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MeusTicketsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus tickets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final criou = await Get.to<bool>(() => const CriarTicketView());
          if (criou == true) controller.carregar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo ticket'),
      ),
      body: Column(
        children: [
          // Filtros (chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() => Row(
                    children: [
                      _Chip(
                        label: 'Todos',
                        selected: controller.estadoFiltro.value == null,
                        onTap: () => controller.filtrarPorEstado(null),
                      ),
                      ...TicketEstado.values.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _Chip(
                              label: e.label,
                              selected: controller.estadoFiltro.value == e,
                              onTap: () => controller.filtrarPorEstado(e),
                            ),
                          )),
                    ],
                  )),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.tickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.erro.value != null && controller.tickets.isEmpty) {
                return _erroState(context, controller);
              }
              if (controller.tickets.isEmpty) {
                return _emptyState(context);
              }

              return RefreshIndicator(
                onRefresh: controller.carregar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final t = controller.tickets[i];
                    return _TicketCard(
                      ticket: t,
                      onTap: () async {
                        await Get.to(() => TicketDetalheView(ticketId: t.id));
                        controller.carregar();
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Sem tickets ainda.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Toca em "Novo ticket" para reportar um problema.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _erroState(BuildContext context, MeusTicketsController c) {
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${ticket.id}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
                  const SizedBox(width: 8),
                  _badge(ticket.estado.label, ticket.estado.cor),
                  const SizedBox(width: 6),
                  _badgePequeno(ticket.prioridade.label, ticket.prioridade.cor),
                  const Spacer(),
                  if (ticket.fotos.isNotEmpty) ...[
                    Icon(Icons.image,
                        size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('${ticket.fotos.length}',
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(ticket.categoria.icon,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ticket.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 12, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    _fmtData(ticket.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (ticket.fraccaoIdentificador != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.home,
                        size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      'Fracção ${ticket.fraccaoIdentificador}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
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
            fontWeight: FontWeight.w600,
          )),
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
            fontWeight: FontWeight.w500,
          )),
    );
  }

  String _fmtData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$min';
  }
}
