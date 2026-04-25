import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/models/visita.dart';
import '../controllers/historico_visitas_controller.dart';

/// Vista do histórico de visitas para o condomino.
///
/// Lista paginada com filtros (data, nome, método).
/// Pull-to-refresh + scroll infinito.
class HistoricoVisitasView extends StatefulWidget {
  const HistoricoVisitasView({super.key});

  @override
  State<HistoricoVisitasView> createState() => _HistoricoVisitasViewState();
}

class _HistoricoVisitasViewState extends State<HistoricoVisitasView> {
  late final HistoricoVisitasController controller;
  final ScrollController _scrollController = ScrollController();
  bool _filtrosExpandidos = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HistoricoVisitasController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.carregarMais();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de visitas'),
        actions: [
          IconButton(
            icon: Icon(_filtrosExpandidos
                ? Icons.filter_list_off
                : Icons.filter_list),
            tooltip: 'Filtros',
            onPressed: () {
              setState(() => _filtrosExpandidos = !_filtrosExpandidos);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtrosExpandidos) _buildFiltros(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.visitas.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.erro.value != null && controller.visitas.isEmpty) {
                return _buildErro(controller.erro.value!);
              }

              if (controller.visitas.isEmpty) {
                return _buildEmpty();
              }

              return RefreshIndicator(
                onRefresh: controller.carregar,
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.visitas.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= controller.visitas.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _buildVisitaCard(controller.visitas[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),

          // Datas
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Desde',
                      value: controller.desde.value,
                      onChanged: (d) => controller.desde.value = d,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateField(
                      label: 'Até',
                      value: controller.ate.value,
                      onChanged: (d) => controller.ate.value = d,
                    ),
                  ),
                ],
              )),

          const SizedBox(height: 12),

          // Nome
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nome do visitante',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => controller.nomeFiltro.value = v,
          ),

          const SizedBox(height: 12),

          // Método
          Obx(() => DropdownButtonFormField<MetodoValidacao?>(
                value: controller.metodoFiltro.value,
                decoration: const InputDecoration(
                  labelText: 'Método',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...MetodoValidacao.values.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label),
                      )),
                ],
                onChanged: (v) => controller.metodoFiltro.value = v,
              )),

          const SizedBox(height: 16),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.limparFiltros,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: controller.carregar,
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitaCard(Visita v) {
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
                Expanded(
                  child: Text(
                    v.visitante?.nome ?? 'Visitante #${v.visitanteId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildMetodoChip(v.metodoValidacao),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.home, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'Fracção ${v.fraccao?.identificador ?? v.fraccaoId}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.login, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(_fmtData(v.entrouEm), style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (v.aindaDentro) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AINDA DENTRO',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(Icons.logout,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(_fmtData(v.saiuEm!),
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.timer,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(_fmtDuracao(v.duracaoMinutos!),
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            if (v.observacoes != null && v.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v.observacoes!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoChip(MetodoValidacao metodo) {
    final colors = switch (metodo) {
      MetodoValidacao.qr => (Colors.blue, Colors.blue.shade700),
      MetodoValidacao.otp => (Colors.purple, Colors.purple.shade700),
      MetodoValidacao.manual => (Colors.orange, Colors.orange.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        metodo.label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            controller.temFiltrosActivos
                ? 'Sem visitas para os filtros aplicados.'
                : 'Ainda não há visitas registadas.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (controller.temFiltrosActivos) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: controller.limparFiltros,
              child: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErro(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
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

  String _fmtDuracao(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
              : '—',
        ),
      ),
    );
  }
}
