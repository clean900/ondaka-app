import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/passe_controller.dart';
import '../models/passe.dart';
import '../repositories/passe_repository.dart';

class PassesView extends StatelessWidget {
  const PassesView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(PasseController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _abrirFormulario(context, c),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Solicitar passe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (c.passes.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Sem passes.\nSolicite um passe para prestadores ou trabalhadores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: c.carregar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: c.passes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PasseCard(passe: c.passes[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario(BuildContext context, PasseController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormularioPasse(c: c),
    );
  }
}

class _PasseCard extends StatelessWidget {
  final Passe passe;
  const _PasseCard({required this.passe});

  Future<void> _comPdf(Future<void> Function(String path) acao) async {
    try {
      final nome = 'passe-${passe.nomeVisitante.replaceAll(' ', '-')}';
      final path = await PasseRepository().descarregarPdf(passe.pdfUrl!, nome: nome);
      await acao(path);
    } catch (_) {
      Get.snackbar('Erro', 'Nao foi possivel abrir o passe.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _abrir() => _comPdf((p) => OpenFile.open(p));
  Future<void> _partilhar() => _comPdf((p) => Share.shareXFiles([XFile(p)]));

  @override
  Widget build(BuildContext context) {
    final cor = switch (passe.estado) {
      'aprovado' => AppColors.success,
      'pendente' => AppColors.warning,
      'recusado' => AppColors.danger,
      _ => AppColors.textMuted,
    };
    final fmt = DateFormat('dd/MM/yy');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(passe.nomeVisitante,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                child: Text(passe.estado.toUpperCase(),
                    style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${passe.tipoAcesso[0].toUpperCase()}${passe.tipoAcesso.substring(1)}'
            '${passe.validaDesde != null ? ' · ${fmt.format(passe.validaDesde!)} → ${fmt.format(passe.validaAte!)}' : ''}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (passe.aprovado && passe.pdfUrl != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _partilhar,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Partilhar passe'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.cyan),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _abrir,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMuted),
                  child: const Icon(Icons.download, size: 20),
                ),
              ],
            ),
          ],
          if (passe.pendente)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('A aguardar aprovação do gestor.',
                  style: TextStyle(color: AppColors.warning, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _FormularioPasse extends StatelessWidget {
  final PasseController c;
  const _FormularioPasse({required this.c});

  Future<void> _pickData(BuildContext context, Rx<DateTime?> alvo) async {
    final d = await showDatePicker(
      context: context,
      initialDate: alvo.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) alvo.value = d;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Solicitar passe', style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (c.fraccoes.isNotEmpty)
              DropdownButtonFormField<int>(
                value: c.fraccaoId.value,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Imóvel'),
                items: c.fraccoes.map((f) => DropdownMenuItem(value: f.id, child: Text(f.identificador))).toList(),
                onChanged: (v) => c.fraccaoId.value = v,
              )
            else
              Row(children: [
                const Expanded(child: Text('Sem imóveis carregados.', style: TextStyle(color: AppColors.warning, fontSize: 12))),
                TextButton(onPressed: c.carregar, child: const Text('Recarregar')),
              ]),
            Row(children: [
              Expanded(child: _seg('Prestador', 'prestador', c)),
              const SizedBox(width: 8),
              Expanded(child: _seg('Trabalhador', 'trabalhador', c)),
            ]),
            TextField(
              decoration: const InputDecoration(labelText: 'Nome do visitante'),
              onChanged: (v) => c.nomeVisitante.value = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => c.telefone.value = v,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Função / Motivo',
                hintText: 'Ex.: Canalizador, Pintor, Motorista',
              ),
              onChanged: (v) => c.funcao.value = v,
            ),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: c.tipoDocumento.value,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Documento'),
                  items: const [
                    DropdownMenuItem(value: 'bi', child: Text('BI')),
                    DropdownMenuItem(value: 'passaporte', child: Text('Passaporte')),
                    DropdownMenuItem(value: 'carta_conducao', child: Text('Carta de condução')),
                    DropdownMenuItem(value: 'outro', child: Text('Outro')),
                  ],
                  onChanged: (v) => c.tipoDocumento.value = v ?? 'bi',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Nº documento'),
                  onChanged: (v) => c.numeroDocumento.value = v,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _dataBtn(context, 'Início', c.validaDesde, fmt)),
              const SizedBox(width: 8),
              Expanded(child: _dataBtn(context, 'Fim', c.validaAte, fmt)),
            ]),
            const SizedBox(height: 12),
            // Foto do visitante (vai no passe) — obrigatória
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: c.tirarFotoVisitante,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(c.fotoPath.value == null ? 'Foto do visitante *' : 'Foto do visitante ✓'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.fotoPath.value == null ? AppColors.textMuted : AppColors.success,
                  ),
                ),
              ),
              IconButton(onPressed: c.escolherFotoVisitante, icon: const Icon(Icons.photo_library, color: AppColors.cyan)),
            ]),
            const SizedBox(height: 8),
            // Documento de identificação — obrigatório
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: c.escolherDocumento,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: Text(c.documentoPath.value == null ? 'Documento de identificação *' : 'Documento anexado ✓'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.documentoPath.value == null ? AppColors.textMuted : AppColors.success,
                  ),
                ),
              ),
              IconButton(onPressed: c.tirarFotoDocumento, icon: const Icon(Icons.camera_alt, color: AppColors.cyan)),
            ]),
            if (c.erro.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(c.erro.value!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: c.aSubmeter.value ? null : () async {
                  final ok = await c.submeter();
                  if (ok && context.mounted) {
                    Navigator.pop(context);
                    Get.snackbar('Passe solicitado', 'A aguardar aprovação do gestor.',
                        backgroundColor: AppColors.success, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                  }
                },
                child: Text(c.aSubmeter.value ? 'A enviar…' : 'Solicitar passe',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _seg(String label, String valor, PasseController c) {
    final sel = c.tipoAcesso.value == valor;
    return GestureDetector(
      onTap: () => c.tipoAcesso.value = valor,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? AppColors.cyan.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? AppColors.cyan : AppColors.textMuted.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: sel ? AppColors.cyan : AppColors.textMuted, fontSize: 13)),
      ),
    );
  }

  Widget _dataBtn(BuildContext context, String label, Rx<DateTime?> alvo, DateFormat fmt) {
    return OutlinedButton(
      onPressed: () => _pickData(context, alvo),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMain, padding: const EdgeInsets.symmetric(vertical: 14)),
      child: Text(alvo.value == null ? label : fmt.format(alvo.value!), style: const TextStyle(fontSize: 12)),
    );
  }
}
