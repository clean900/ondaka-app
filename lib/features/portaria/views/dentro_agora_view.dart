import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/models/visita.dart';
import '../controllers/dentro_agora_controller.dart';

/// Ecrã "Quem está dentro agora".
///
/// Lista visitas activas (ainda não saíram) e permite marcar saída.
class DentroAgoraView extends StatelessWidget {
  const DentroAgoraView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DentroAgoraController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Obx(() => Text(
              'Quem está dentro${controller.visitas.isNotEmpty ? " (${controller.visitas.length})" : ""}',
            )),
        backgroundColor: AppColors.bgDark,
      ),
      body: Obx(() {
        // Loading inicial
        if (controller.isLoading.value && controller.visitas.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.cyan,
            ),
          );
        }

        // Erro (lista vazia + erro)
        if (controller.errorMessage.value != null && controller.visitas.isEmpty) {
          return _erroView(controller);
        }

        // Lista vazia sem erro
        if (controller.visitas.isEmpty) {
          return _listaVaziaView(controller);
        }

        // Lista com pull-to-refresh
        return RefreshIndicator(
          color: AppColors.cyan,
          onRefresh: controller.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.visitas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final visita = controller.visitas[index];
              return _visitaCard(context, controller, visita);
            },
          ),
        );
      }),
    );
  }

  // === Sub-widgets ===

  Widget _erroView(DentroAgoraController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            controller.errorMessage.value!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.carregar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _listaVaziaView(DentroAgoraController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            color: Colors.white.withValues(alpha: 0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum visitante dentro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O condomínio está vazio de visitas agora.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: controller.carregar,
            icon: const Icon(Icons.refresh, color: AppColors.cyanSoft),
            label: const Text(
              'Actualizar',
              style: TextStyle(color: AppColors.cyanSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitaCard(
    BuildContext context,
    DentroAgoraController controller,
    Visita visita,
  ) {
    final emProgresso = controller.saidaEmProgresso(visita.id);
    final minutosDentro = DateTime.now().difference(visita.entrouEm).inMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome + método
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: AppColors.cyanSoft, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visita.visitante?.nome ?? 'Visitante',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visita.fraccao?.label ?? 'Fracção #${visita.fraccaoId}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info adicional
          Row(
            children: [
              _chipInfo(
                icon: Icons.login,
                label: 'Entrada: ${_formatarHora(visita.entrouEm)}',
              ),
              const SizedBox(width: 8),
              _chipInfo(
                icon: Icons.timer,
                label: _formatarDuracao(minutosDentro),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botão marcar saída
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: emProgresso
                  ? null
                  : () => _confirmarSaida(context, controller, visita),
              icon: emProgresso
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.logout, size: 18),
              label: Text(emProgresso ? 'A registar...' : 'MARCAR SAÍDA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipInfo({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.cyanSoft, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSaida(
    BuildContext context,
    DentroAgoraController controller,
    Visita visita,
  ) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'Marcar saída',
      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      middleText:
          'Registar saída de ${visita.visitante?.nome ?? "este visitante"}?',
      middleTextStyle:
          const TextStyle(color: AppColors.textMuted, fontSize: 13),
      backgroundColor: AppColors.surface,
      radius: 14,
      textCancel: 'Cancelar',
      textConfirm: 'Marcar saída',
      confirmTextColor: AppColors.bgDark,
      buttonColor: AppColors.cyan,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirm == true) {
      await controller.marcarSaida(visita.id);
    }
  }

  String _formatarHora(DateTime dt) {
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  String _formatarDuracao(int minutos) {
    if (minutos < 60) return 'há $minutos min';
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    if (resto == 0) return 'há ${horas}h';
    return 'há ${horas}h ${resto}min';
  }
}
