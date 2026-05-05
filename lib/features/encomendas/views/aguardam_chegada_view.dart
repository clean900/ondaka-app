import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/minhas_encomendas_controller.dart';
import '../models/encomenda.dart';
import '../widgets/encomenda_card.dart';
import 'criar_pre_anuncio_view.dart';

class AguardamChegadaView extends StatelessWidget {
  const AguardamChegadaView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MinhasEncomendasController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.encomendas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null && controller.encomendas.isEmpty) {
          return _ErroView(
            mensagem: controller.erro.value!,
            onRetry: controller.carregar,
          );
        }
        if (controller.aguardamChegada.isEmpty) {
          return _VazioView(
            icon: Icons.schedule_outlined,
            titulo: 'Sem pré-anúncios',
            subtitulo:
                'Cria um pré-anúncio para avisar a portaria de uma encomenda que está a chegar.',
          );
        }

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: controller.aguardamChegada.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final e = controller.aguardamChegada[index];
              return EncomendaCard(
                encomenda: e,
                isCancelando: controller.isCancelando(e.id),
                onCancelar: () => _confirmarCancelar(context, controller, e),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CriarPreAnuncioView()),
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Pré-anunciar'),
      ),
    );
  }

  void _confirmarCancelar(
    BuildContext context,
    MinhasEncomendasController controller,
    Encomenda e,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar pré-anúncio?'),
        content: Text(
          'Tem a certeza que quer cancelar o pré-anúncio "${e.descricao}"?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Não')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelar(e.id);
            },
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
  }
}

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _ErroView({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

class _VazioView extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  const _VazioView({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
