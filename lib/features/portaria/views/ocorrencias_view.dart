import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../models/ocorrencia_portaria.dart';
import '../repositories/portaria_repository.dart';

/// Livro de ocorrências da portaria (add-on livro_ocorrencias).
class OcorrenciasView extends StatefulWidget {
  const OcorrenciasView({super.key});

  @override
  State<OcorrenciasView> createState() => _OcorrenciasViewState();
}

class _OcorrenciasViewState extends State<OcorrenciasView> {
  final _repo = PortariaRepository();
  final _picker = ImagePicker();
  List<OcorrenciaPortaria> _itens = [];
  bool _carregando = true;
  bool _aProcessar = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final l = await _repo.listarOcorrencias();
      if (mounted) setState(() => _itens = l);
    } catch (_) {
      if (mounted) Get.snackbar('Ocorrências', 'Não foi possível carregar.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark, title: const Text('Livro de ocorrências')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _aProcessar ? null : _abrirForm,
        backgroundColor: AppColors.cyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nova ocorrência', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : RefreshIndicator(
              color: AppColors.cyan,
              onRefresh: _carregar,
              child: _itens.isEmpty
                  ? ListView(children: const [SizedBox(height: 140), Center(child: Text('Sem ocorrências registadas.', style: TextStyle(color: AppColors.textMuted)))])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _itens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _card(_itens[i]),
                    ),
            ),
    );
  }

  Widget _card(OcorrenciaPortaria o) {
    final cor = switch (o.tipo) {
      'incidente' => AppColors.warning,
      'alerta' => AppColors.danger,
      _ => AppColors.cyan,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: o.estaAberta ? cor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(o.tipoLabel, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(_hora(o.criadaEm), style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(o.descricao, style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (o.fotoUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(o.fotoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (o.guardaNome != null)
                Expanded(child: Text(o.guardaNome!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
              if (o.estaAberta)
                TextButton(
                  onPressed: _aProcessar ? null : () => _resolver(o),
                  child: const Text('Resolver', style: TextStyle(color: AppColors.successSoft, fontWeight: FontWeight.w700)),
                )
              else
                const Text('Resolvida', style: TextStyle(color: AppColors.successSoft, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolver(OcorrenciaPortaria o) async {
    setState(() => _aProcessar = true);
    try {
      final at = await _repo.resolverOcorrencia(o.id);
      if (!mounted) return;
      setState(() {
        final i = _itens.indexWhere((x) => x.id == o.id);
        if (i != -1) _itens[i] = at;
      });
    } catch (_) {
      Get.snackbar('Ocorrências', 'Não foi possível resolver.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _aProcessar = false);
    }
  }

  void _abrirForm() {
    final descricao = TextEditingController();
    String tipo = 'observacao';
    File? foto;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nova ocorrência', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in const ['observacao', 'incidente', 'alerta'])
                      ChoiceChip(
                        label: Text(t == 'observacao' ? 'Observação' : (t == 'incidente' ? 'Incidente' : 'Alerta')),
                        selected: tipo == t,
                        onSelected: (_) => setSheet(() => tipo = t),
                        selectedColor: AppColors.cyan.withValues(alpha: 0.25),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        labelStyle: TextStyle(color: tipo == t ? AppColors.cyanSoft : AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descricao,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Descreva a ocorrência' : null,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cyan)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final img = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 70);
                        if (img != null) setSheet(() => foto = File(img.path));
                      },
                      icon: const Icon(Icons.photo_camera_outlined, color: AppColors.cyanSoft, size: 18),
                      label: Text(foto == null ? 'Foto (opcional)' : 'Foto anexada', style: const TextStyle(color: AppColors.cyanSoft)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Get.back();
                      await _criar(tipo, descricao.text.trim(), foto);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Registar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _criar(String tipo, String descricao, File? foto) async {
    setState(() => _aProcessar = true);
    try {
      final o = await _repo.criarOcorrencia(tipo: tipo, descricao: descricao, foto: foto);
      if (!mounted) return;
      setState(() => _itens.insert(0, o));
    } catch (_) {
      Get.snackbar('Ocorrências', 'Não foi possível registar.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _aProcessar = false);
    }
  }

  String _hora(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
