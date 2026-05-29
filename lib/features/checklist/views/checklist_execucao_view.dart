import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checklist_controller.dart';
import '../models/checklist_modelo.dart';
import '../../../app/theme/app_colors.dart';

class ChecklistExecucaoView extends StatefulWidget {
  final ChecklistModelo modelo;
  const ChecklistExecucaoView({super.key, required this.modelo});

  @override
  State<ChecklistExecucaoView> createState() => _ChecklistExecucaoViewState();
}

class _ChecklistExecucaoViewState extends State<ChecklistExecucaoView> {
  final Map<int, bool> _ok = {};
  final Map<int, TextEditingController> _notas = {};
  final TextEditingController _obs = TextEditingController();
  bool _aSubmeter = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.modelo.itens) {
      _ok[item.id] = false; // comeca 'por fazer'; utilizador marca como concluido
      _notas[item.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _notas.values) {
      c.dispose();
    }
    _obs.dispose();
    super.dispose();
  }

  bool get _obrigatoriosOk {
    for (final item in widget.modelo.itens) {
      // itens obrigatórios têm de estar concluídos para submeter
      if (item.obrigatorio && _ok[item.id] != true) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submeter() async {
    setState(() => _aSubmeter = true);
    final c = Get.find<ChecklistController>();
    final respostas = widget.modelo.itens.map((item) {
      return {
        'item_id': item.id,
        'ok': _ok[item.id] ?? false,
        if ((_notas[item.id]?.text ?? '').trim().isNotEmpty) 'nota': _notas[item.id]!.text.trim(),
      };
    }).toList();

    final sucesso = await c.submeter(
      modeloId: widget.modelo.id,
      respostas: respostas,
      observacoes: _obs.text.trim(),
    );

    setState(() => _aSubmeter = false);

    if (sucesso) {
      Get.back();
      Get.snackbar('Concluído', 'Checklist submetida com sucesso.',
          backgroundColor: AppColors.success, colorText: const Color(0xFFFFFFFF));
    } else {
      Get.snackbar('Erro', 'Não foi possível submeter. Tente novamente.',
          backgroundColor: AppColors.dangerSoft, colorText: const Color(0xFFFFFFFF));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.modelo.nome),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.modelo.descricao != null && widget.modelo.descricao!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(widget.modelo.descricao!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          ...widget.modelo.itens.map((item) {
            final ok = _ok[item.id] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.texto + (item.obrigatorio ? ' *' : ''),
                          style: const TextStyle(color: AppColors.textMain, fontSize: 14),
                        ),
                      ),
                      Switch(
                        value: ok,
                        activeColor: AppColors.success,
                        onChanged: (v) => setState(() => _ok[item.id] = v),
                      ),
                    ],
                  ),
                  if (ok)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _notas[item.id],
                        style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Comentário (opcional)',
                          hintStyle: const TextStyle(color: AppColors.textFaint),
                          filled: true,
                          fillColor: AppColors.bgDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _obs,
            style: const TextStyle(color: AppColors.textMain, fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Observações gerais (opcional)',
              hintStyle: const TextStyle(color: AppColors.textFaint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_aSubmeter || !_obrigatoriosOk) ? null : _submeter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _aSubmeter ? 'A submeter...' : 'Submeter checklist',
                style: const TextStyle(color: Color(0xFF0A0A1A), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (!_obrigatoriosOk)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Conclua os itens obrigatórios (*) para submeter.',
                style: TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
