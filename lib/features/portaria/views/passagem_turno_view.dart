import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/portaria_repository.dart';

/// Passagem de turno da portaria (add-on livro_ocorrencias).
class PassagemTurnoView extends StatefulWidget {
  const PassagemTurnoView({super.key});

  @override
  State<PassagemTurnoView> createState() => _PassagemTurnoViewState();
}

class _PassagemTurnoViewState extends State<PassagemTurnoView> {
  final _repo = PortariaRepository();
  final _resumo = TextEditingController();
  List<Map<String, dynamic>> _recentes = [];
  bool _carregando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _resumo.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final l = await _repo.listarPassagensTurno();
      if (mounted) setState(() => _recentes = l);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviar() async {
    final r = _resumo.text.trim();
    if (r.length < 3) {
      Get.snackbar('Passagem de turno', 'Escreva um resumo.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _enviando = true);
    try {
      await _repo.criarPassagemTurno(r);
      _resumo.clear();
      await _carregar();
      Get.snackbar('Passagem de turno', 'Registada com sucesso.', snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Passagem de turno', 'Não foi possível registar.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark, title: const Text('Passagem de turno')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Resumo para o próximo turno', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: _resumo,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ex.: 2 visitantes ainda dentro, portão B com fecho avariado…',
              hintStyle: const TextStyle(color: AppColors.textFaint),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cyan)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _enviando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Registar passagem', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Passagens recentes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          if (_carregando)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.cyan)))
          else if (_recentes.isEmpty)
            const Text('Ainda sem passagens.', style: TextStyle(color: AppColors.textMuted))
          else
            ..._recentes.map(_cardPassagem),
        ],
      ),
    );
  }

  Widget _cardPassagem(Map<String, dynamic> p) {
    final guarda = (p['guarda'] as Map?)?['name']?.toString() ?? 'Guarda';
    final data = p['created_at'] != null ? DateTime.tryParse(p['created_at'] as String)?.toLocal() : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(guarda, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              if (data != null)
                Text('${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(p['resumo']?.toString() ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Text('${p['total_dentro'] ?? 0} dentro · ${p['ocorrencias_abertas'] ?? 0} ocorrências abertas',
              style: const TextStyle(color: AppColors.cyanSoft, fontSize: 11.5)),
        ],
      ),
    );
  }
}
