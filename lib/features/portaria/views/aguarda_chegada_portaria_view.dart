import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../encomendas/models/encomenda.dart';
import '../controllers/portaria_encomendas_controller.dart';

/// Sub-tab "Aguardam" do shell de portaria.
///
/// Lista pré-anúncios em `aguarda_chegada` para o guarda confirmar
/// quando chegam à portaria.
class AguardaChegadaPortariaView extends StatelessWidget {
  const AguardaChegadaPortariaView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PortariaEncomendasController>();

    return Obx(() {
      if (controller.isLoadingAguarda.value && controller.aguardaChegada.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.aguardaChegada.isEmpty) {
        return _vazio();
      }

      return RefreshIndicator(
        onRefresh: controller.carregarAguardaChegada,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: controller.aguardaChegada.length,
          itemBuilder: (context, index) {
            final e = controller.aguardaChegada[index];
            return _PreAnuncioCard(
              encomenda: e,
              onMarcarChegada: () => _confirmarChegada(context, e, controller),
            );
          },
        ),
      );
    });
  }

  Future<void> _confirmarChegada(
    BuildContext context,
    Encomenda e,
    PortariaEncomendasController controller,
  ) async {
    final notas = await showDialog<String?>(
      context: context,
      builder: (ctx) => _NotasDialog(
        titulo: 'Marcar chegada',
        descricao: 'Encomenda: ${e.descricao}',
      ),
    );

    if (notas == null) return; // cancelado

    await controller.marcarChegada(e.id, notas: notas.isEmpty ? null : notas);
  }

  Widget _vazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text(
            'Sem pré-anúncios pendentes.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quando um condómino pré-anuncia uma encomenda, aparece aqui.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PreAnuncioCard extends StatelessWidget {
  const _PreAnuncioCard({
    required this.encomenda,
    required this.onMarcarChegada,
  });

  final Encomenda encomenda;
  final VoidCallback onMarcarChegada;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule, color: AppColors.cyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        encomenda.descricao,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (encomenda.fraccao != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Imóvel ${encomenda.fraccao!.identificador}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (encomenda.remetente != null && encomenda.remetente!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _info(Icons.local_shipping_outlined, encomenda.remetente!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarcarChegada,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Marcar chegada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: const Color(0xFF001218),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _NotasDialog extends StatefulWidget {
  const _NotasDialog({required this.titulo, required this.descricao});

  final String titulo;
  final String descricao;

  @override
  State<_NotasDialog> createState() => _NotasDialogState();
}

class _NotasDialogState extends State<_NotasDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.titulo, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.descricao,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Notas (opcional)...',
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: const Color(0xFF001218),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
