import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/assembleia_detalhe_controller.dart';
import '../models/assembleia.dart';

class AssembleiaDetalheView extends StatefulWidget {
  final int assembleiaId;
  const AssembleiaDetalheView({super.key, required this.assembleiaId});

  @override
  State<AssembleiaDetalheView> createState() => _AssembleiaDetalheViewState();
}

class _AssembleiaDetalheViewState extends State<AssembleiaDetalheView> {
  late final AssembleiaDetalheController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      AssembleiaDetalheController(assembleiaId: widget.assembleiaId),
      tag: 'assembleia-${widget.assembleiaId}',
    );
  }

  @override
  void dispose() {
    Get.delete<AssembleiaDetalheController>(
        tag: 'assembleia-${widget.assembleiaId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assembleia')),
      body: Obx(() {
        if (controller.isLoading.value && controller.detalhe.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null) {
          return _erroState();
        }
        final d = controller.detalhe.value;
        if (d == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _cabecalho(d),
              const SizedBox(height: 16),
              if (d.assembleia.ordemDoDia != null) _ordemDoDia(d),
              if (d.assembleia.modo == 'virtual' &&
                  d.assembleia.salaJitsi != null) ...[
                const SizedBox(height: 16),
                _botaoJitsi(d),
              ],
              if (d.assembleia.actaGerada &&
                  d.assembleia.actaPath != null) ...[
                const SizedBox(height: 16),
                _botaoActa(d),
              ],
              const SizedBox(height: 16),
              _pontos(d),
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

  Widget _cabecalho(AssembleiaDetalhe d) {
    final theme = Theme.of(context);
    final a = d.assembleia;
    return Card(
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
                    color: a.estado.cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: a.estado.cor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    a.estado.label,
                    style: TextStyle(
                        color: a.estado.cor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Text(a.numero,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline)),
              ],
            ),
            const SizedBox(height: 12),
            Text(a.titulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 6),
                Text(_fmtDataLonga(a.dataAgendada),
                    style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  a.modo == 'virtual'
                      ? Icons.videocam
                      : Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    a.local ?? (a.modo == 'virtual' ? 'Virtual' : 'Presencial'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tens ${d.numeroFraccoes} fracção(ões) — ${d.permilagemTotal.toStringAsFixed(2)}‰',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ordemDoDia(AssembleiaDetalhe d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ordem do dia',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(d.assembleia.ordemDoDia!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _botaoJitsi(AssembleiaDetalhe d) {
    return FilledButton.icon(
      onPressed: () async {
        final url = 'https://meet.jit.si/${d.assembleia.salaJitsi}';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.videocam),
      label: const Text('Entrar na sala virtual'),
      style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: Colors.blue),
    );
  }

  Widget _botaoActa(AssembleiaDetalhe d) {
    return OutlinedButton.icon(
      onPressed: () async {
        final url = 'https://ondaka.ao/storage/${d.assembleia.actaPath}';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.description),
      label: const Text('Ver acta'),
      style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50)),
    );
  }

  Widget _pontos(AssembleiaDetalhe d) {
    if (d.pontos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('Sem pontos de votação.',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pontos de votação (${d.pontos.length})',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...d.pontos.map((p) => _PontoCard(
              ponto: p,
              onVotar: (opcao) => controller.votar(
                pontoId: p.id,
                opcao: opcao,
              ),
            )),
      ],
    );
  }

  String _fmtDataLonga(DateTime dt) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final dia = dt.day.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia ${meses[dt.month - 1]} ${dt.year} - $hora:$min';
  }
}

class _PontoCard extends StatelessWidget {
  final PontoVotacao ponto;
  final Future<bool> Function(String opcao) onVotar;

  const _PontoCard({required this.ponto, required this.onVotar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text('${ponto.ordem}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ponto.titulo,
                      style: theme.textTheme.titleSmall),
                ),
                _badgeEstado(ponto.estado),
              ],
            ),
            if (ponto.descricao != null && ponto.descricao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(ponto.descricao!,
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            if (ponto.meuVoto != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Votaste: ${ponto.meuVoto}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else if (ponto.votacaoAberta)
              _botoesVotacao(context)
            else
              Text(
                ponto.estado == 'aberta'
                    ? 'Votação aberta — aguarda...'
                    : 'Votação encerrada.',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _badgeEstado(String estado) {
    final cor = estado == 'aberta'
        ? Colors.green
        : (estado == 'encerrada' ? Colors.grey : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(estado,
          style: TextStyle(
              color: cor, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _botoesVotacao(BuildContext context) {
    // Opções padrão: Sim/Não/Abstenção
    final opcoes = ponto.opcoes.isNotEmpty
        ? ponto.opcoes.map((e) => e.toString()).toList()
        : ['Sim', 'Não', 'Abstenção'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opcoes
          .map((opt) => OutlinedButton(
                onPressed: () => _confirmarVoto(context, opt),
                child: Text(opt),
              ))
          .toList(),
    );
  }

  Future<void> _confirmarVoto(BuildContext context, String opcao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar voto'),
        content: Text(
            'Tens a certeza que queres votar "$opcao"?\n\nO voto não pode ser alterado depois.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Votar')),
        ],
      ),
    );
    if (ok == true) {
      await onVotar(opcao);
    }
  }
}
