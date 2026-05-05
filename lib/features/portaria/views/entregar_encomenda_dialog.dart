import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../encomendas/models/encomenda.dart';
import '../controllers/portaria_encomendas_controller.dart';

/// Dialog para o guarda registar entrega de uma encomenda.
///
/// Opção simples: o guarda escreve o nome de quem levantou (titular ou
/// pessoa autorizada). Versão futura pode listar autorizados pré-cadastrados.
class EntregarEncomendaDialog extends StatefulWidget {
  const EntregarEncomendaDialog({super.key, required this.encomenda});

  final Encomenda encomenda;

  @override
  State<EntregarEncomendaDialog> createState() =>
      _EntregarEncomendaDialogState();
}

class _EntregarEncomendaDialogState extends State<EntregarEncomendaDialog> {
  final _nomeCtrl = TextEditingController();
  bool _aProcessar = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      Get.snackbar(
        'Nome obrigatório',
        'Indica quem levantou a encomenda.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _aProcessar = true);

    final controller = Get.find<PortariaEncomendasController>();
    final ok = await controller.entregar(
      widget.encomenda.id,
      levantadaPor: nome,
    );

    if (mounted) {
      setState(() => _aProcessar = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fraccaoLabel = widget.encomenda.fraccao != null
        ? 'Imóvel ${widget.encomenda.fraccao!.identificador}'
        : 'Imóvel desconhecido';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Entregar encomenda',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.encomenda.descricao,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fraccaoLabel,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Text(
            'Quem levantou?',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nomeCtrl,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Nome do titular ou pessoa autorizada',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _aProcessar ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: _aProcessar ? null : _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: const Color(0xFF001218),
          ),
          child: _aProcessar
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF001218),
                  ),
                )
              : const Text('Confirmar entrega'),
        ),
      ],
    );
  }
}
