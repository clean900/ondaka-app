import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../services/webrtc_call_service.dart';

/// Ecrã da chamada de voz em curso (estilo telefone): nome do outro,
/// estado/cronómetro, e controlos (mudo, altifalante, desligar).
class ChamadaEmCursoView extends StatelessWidget {
  const ChamadaEmCursoView({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = WebrtcCallService.to;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 64),
                ),
                const SizedBox(height: 28),
                Obx(() => Text(
                      svc.nomeOutro.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMain, fontSize: 26, fontWeight: FontWeight.w700),
                    )),
                const SizedBox(height: 10),
                Obx(() => Text(
                      _legendaEstado(svc),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 16, letterSpacing: 1),
                    )),
                const Spacer(),
                // Controlos: mudo + altifalante (só fazem sentido em curso/ligar peer).
                Obx(() {
                  final podeControlar = svc.estado.value == EstadoChamada.emCurso ||
                      svc.estado.value == EstadoChamada.aLigarPeer;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _controlo(
                        icon: svc.mudo.value ? Icons.mic_off : Icons.mic,
                        label: 'Mudo',
                        activo: svc.mudo.value,
                        onTap: podeControlar ? svc.alternarMute : null,
                      ),
                      _controlo(
                        icon: svc.altifalante.value ? Icons.volume_up : Icons.volume_down,
                        label: 'Altifalante',
                        activo: svc.altifalante.value,
                        onTap: podeControlar ? svc.alternarAltifalante : null,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 36),
                // Desligar
                GestureDetector(
                  onTap: svc.desligar,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Desligar', style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _legendaEstado(WebrtcCallService svc) {
    switch (svc.estado.value) {
      case EstadoChamada.aLigar:
        return 'A ligar…';
      case EstadoChamada.aLigarPeer:
        return 'A estabelecer…';
      case EstadoChamada.emCurso:
        return svc.duracaoFmt;
      case EstadoChamada.terminada:
        return 'Terminada';
      default:
        return '';
    }
  }

  Widget _controlo({
    required IconData icon,
    required String label,
    required bool activo,
    required VoidCallback? onTap,
  }) {
    final cor = activo ? AppColors.cyan : AppColors.surface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cor.withValues(alpha: activo ? 1 : 0.6),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: activo ? Colors.white : AppColors.textMain, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }
}
