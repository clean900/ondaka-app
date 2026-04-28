import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/meus_avisos_controller.dart';
import '../models/aviso.dart';
import 'aviso_detalhe_view.dart';

class MeusAvisosView extends StatelessWidget {
  const MeusAvisosView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MeusAvisosController());

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: Obx(() {
        if (controller.isLoading.value && controller.avisos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null && controller.avisos.isEmpty) {
          return _erroState(context, controller);
        }
        if (controller.avisos.isEmpty) {
          return _emptyState(context);
        }

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.avisos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final a = controller.avisos[i];
              return _AvisoCard(
                aviso: a,
                onTap: () async {
                  await Get.to(() => AvisoDetalheView(avisoId: a.id));
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
            Icon(Icons.notifications_none,
                size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Sem avisos no momento.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Quando o admin publicar avisos, aparecem aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _erroState(BuildContext context, MeusAvisosController c) {
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

class _AvisoCard extends StatelessWidget {
  final Aviso aviso;
  final VoidCallback onTap;

  const _AvisoCard({required this.aviso, required this.onTap});

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
                  Icon(aviso.categoria.icon,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  _badgePequeno(aviso.prioridade.label, aviso.prioridade.cor),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(aviso.categoria.label,
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w500)),
                  ),
                  const Spacer(),
                  if (aviso.anexos.isNotEmpty) ...[
                    Icon(Icons.attach_file,
                        size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 2),
                    Text('${aviso.anexos.length}',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                  ],
                  if ((aviso.comentariosCount ?? 0) > 0) ...[
                    Icon(Icons.comment,
                        size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 2),
                    Text('${aviso.comentariosCount}',
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                aviso.titulo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                aviso.descricao.replaceAll(RegExp(r'<[^>]*>'), ''),
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
                    _fmtData(aviso.publicadoEm ?? aviso.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.person,
                      size: 12, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(aviso.autorNome ?? 'Admin',
                      style: theme.textTheme.bodySmall),
                  if (aviso.requerConfirmacao && !aviso.jaConfirmado) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Requer confirmação',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
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

  Widget _badgePequeno(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w500)),
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
