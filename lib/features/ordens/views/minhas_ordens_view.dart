import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/minhas_ordens_controller.dart';
import '../models/ordem.dart';

class MinhasOrdensView extends StatelessWidget {
  const MinhasOrdensView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MinhasOrdensController());

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas ordens')),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() => Row(
                    children: [
                      _Chip(
                        label: 'Todas',
                        selected: controller.estadoFiltro.value == null,
                        onTap: () => controller.filtrar(null),
                      ),
                      ...OrdemEstado.values.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _Chip(
                              label: e.label,
                              selected: controller.estadoFiltro.value == e.slug,
                              onTap: () => controller.filtrar(e.slug),
                            ),
                          )),
                    ],
                  )),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.ordens.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.erro.value != null && controller.ordens.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(controller.erro.value!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              if (controller.ordens.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 72,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('Sem ordens para mostrar.',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.carregar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.ordens.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _OrdemCard(ordem: controller.ordens[i]),
                ),
              );
            }),
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

class _OrdemCard extends StatelessWidget {
  final Ordem ordem;
  const _OrdemCard({required this.ordem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(ordem.numero,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ordem.estado.cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: ordem.estado.cor.withValues(alpha: 0.3)),
                  ),
                  child: Text(ordem.estado.label,
                      style: TextStyle(
                          color: ordem.estado.cor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (ordem.descricaoItem != null)
              Text(
                ordem.descricaoItem!,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${_fmtMoeda(ordem.valorTotal)} AOA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time,
                    size: 12, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(_fmtData(ordem.createdAt),
                    style: theme.textTheme.bodySmall),
              ],
            ),
            if (ordem.numeroFactura != null) ...[
              const SizedBox(height: 6),
              Text('Factura: ${ordem.numeroFactura}',
                  style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtMoeda(double v) {
    final fixed = v.toStringAsFixed(2);
    return fixed.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _fmtData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year}';
  }
}
