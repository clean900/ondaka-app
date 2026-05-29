import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/reservas_controller.dart';
import 'pedir_reserva_view.dart';
import 'minhas_reservas_view.dart';

class ReservasView extends StatelessWidget {
  const ReservasView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ReservasController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Reservas'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Minhas reservas',
            icon: const Icon(Icons.history, color: AppColors.cyan),
            onPressed: () => Get.to(() => const MinhasReservasView()),
          ),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.espacos.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (!c.addonActivo.value) {
          return const _AddonBloqueado();
        }
        if (c.erro.value != null && c.espacos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(c.erro.value!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          );
        }
        if (c.espacos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Não há espaços disponíveis para reservar de momento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.cyan,
          backgroundColor: AppColors.surface,
          onRefresh: c.refrescar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: c.espacos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final e = c.espacos[i];
              return InkWell(
                onTap: () => Get.to(() => PedirReservaView(espaco: e)),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_available, color: AppColors.cyan, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.nome, style: const TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '${e.horaAbertura}–${e.horaFecho} · ${e.duracaoMinHoras}–${e.duracaoMaxHoras}h${e.temCaucao ? ' · caução' : ''}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textFaint),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _AddonBloqueado extends StatelessWidget {
  const _AddonBloqueado();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_outline, size: 32, color: AppColors.textFaint),
            ),
            const SizedBox(height: 16),
            const Text(
              'Funcionalidade não disponível',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMain),
            ),
            const SizedBox(height: 8),
            const Text(
              'A administração do seu condomínio ainda não activou as reservas de áreas comuns. Fale com a gestão para o disponibilizar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
