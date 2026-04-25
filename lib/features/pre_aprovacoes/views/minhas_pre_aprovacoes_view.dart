import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../models/pre_aprovacao.dart';
import '../controllers/minhas_pre_aprovacoes_controller.dart';

/// Lista as pré-aprovações do condomino com filtros por estado.
class MinhasPreAprovacoesView extends StatelessWidget {
  const MinhasPreAprovacoesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MinhasPreAprovacoesController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas pré-aprovações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova pré-aprovação',
            onPressed: () => Get.toNamed(AppRoutes.criarPreAprovacao),
          ),
        ],
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
                      _ChipFiltro(
                        label: 'Todas',
                        selected: controller.estadoFiltro.value == null,
                        onTap: () => controller.filtrarPorEstado(null),
                      ),
                      ...EstadoPreAprovacao.values.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _ChipFiltro(
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
              if (controller.isLoading.value &&
                  controller.preAprovacoes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.erro.value != null &&
                  controller.preAprovacoes.isEmpty) {
                return _buildErro(context, controller);
              }

              if (controller.preAprovacoes.isEmpty) {
                return _buildEmpty(context, controller);
              }

              return RefreshIndicator(
                onRefresh: controller.carregar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.preAprovacoes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pa = controller.preAprovacoes[index];
                    return _PreAprovacaoCard(
                      preAprovacao: pa,
                      isCancelando: controller.isCancelando(pa.id),
                      onCancelar: () => _confirmarCancelar(context, controller, pa),
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

  void _confirmarCancelar(
    BuildContext context,
    MinhasPreAprovacoesController controller,
    PreAprovacao pa,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar pré-aprovação?'),
        content: Text(
          'Tem a certeza que quer cancelar a pré-aprovação de "${pa.nomeVisitante}"?\n\nO visitante já não poderá entrar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Não'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              Get.back();
              controller.cancelar(pa.id);
            },
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, MinhasPreAprovacoesController c) {
    final filtroActivo = c.estadoFiltro.value != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available,
                size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              filtroActivo
                  ? 'Sem pré-aprovações neste estado.'
                  : 'Ainda não criou nenhuma pré-aprovação.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.criarPreAprovacao),
              icon: const Icon(Icons.add),
              label: const Text('Pré-aprovar visitante'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErro(BuildContext context, MinhasPreAprovacoesController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(c.erro.value!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: c.carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipFiltro({
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

class _PreAprovacaoCard extends StatelessWidget {
  final PreAprovacao preAprovacao;
  final bool isCancelando;
  final VoidCallback onCancelar;

  const _PreAprovacaoCard({
    required this.preAprovacao,
    required this.isCancelando,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pa = preAprovacao;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pa.nomeVisitante,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _EstadoBadge(estado: pa.estado),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone,
                    size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(pa.telefoneVisitante,
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.home,
                    size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'Fracção ${pa.fraccao?.identificador ?? pa.fraccaoId}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event,
                    size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text('Válida até ${_fmtData(pa.validaAte)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),

            // Mostrar OTP se ainda pendente (útil para condomino partilhar)
            if (pa.estaPendente) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Código OTP: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      pa.otpCode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botão Cancelar (só se pendente)
            if (pa.estaPendente) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: isCancelando ? null : onCancelar,
                  icon: isCancelando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(isCancelando ? 'A cancelar...' : 'Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

class _EstadoBadge extends StatelessWidget {
  final EstadoPreAprovacao estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final colors = switch (estado) {
      EstadoPreAprovacao.pendente => (Colors.amber, Colors.amber.shade700),
      EstadoPreAprovacao.usada => (Colors.green, Colors.green.shade700),
      EstadoPreAprovacao.expirada => (Colors.grey, Colors.grey.shade700),
      EstadoPreAprovacao.cancelada => (Colors.red, Colors.red.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
