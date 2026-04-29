import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/minhas_assembleias_controller.dart';
import '../models/assembleia.dart';
import 'assembleia_detalhe_view.dart';

class MinhasAssembleiasView extends StatelessWidget {
  const MinhasAssembleiasView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MinhasAssembleiasController());

    return Scaffold(
      appBar: AppBar(title: const Text('Assembleias')),
      body: Obx(() {
        if (controller.isLoading.value && controller.assembleias.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null && controller.assembleias.isEmpty) {
          return _erroState(context, controller);
        }
        if (controller.assembleias.isEmpty) {
          return _emptyState(context);
        }

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.assembleias.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final a = controller.assembleias[i];
              return _AssembleiaCard(
                assembleia: a,
                onTap: () async {
                  await Get.to(() => AssembleiaDetalheView(assembleiaId: a.id));
                  controller.carregar();
                },
              );
            },
          ),
        );
      }),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined,
                size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Sem assembleias.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Quando fores convocado para uma assembleia, aparece aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _erroState(BuildContext context, MinhasAssembleiasController c) {
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

class _AssembleiaCard extends StatelessWidget {
  final Assembleia assembleia;
  final VoidCallback onTap;

  const _AssembleiaCard({required this.assembleia, required this.onTap});

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: assembleia.estado.cor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: assembleia.estado.cor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      assembleia.estado.label,
                      style: TextStyle(
                          color: assembleia.estado.cor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(assembleia.numero,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline)),
                  const Spacer(),
                  if (assembleia.actaGerada)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description,
                              size: 10, color: Colors.green),
                          SizedBox(width: 2),
                          Text('Acta',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(assembleia.titulo,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(_fmtData(assembleia.dataAgendada),
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(
                    assembleia.modo == 'virtual'
                        ? Icons.videocam_outlined
                        : Icons.location_on_outlined,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      assembleia.local ?? assembleia.modo,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} $hora:$min';
  }
}
