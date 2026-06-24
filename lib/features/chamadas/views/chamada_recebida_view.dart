import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../utils/chamada_ring.dart';

/// Ecrã full-screen de chamada recebida (estilo SOS): toca em loop, Atender abre
/// a sala de áudio no servidor próprio, Recusar fecha.
class ChamadaRecebidaView extends StatefulWidget {
  final String quemLiga;
  final String jitsiUrl; // já com token (entrada autenticada)
  final String origem; // 'portaria' ou 'condomino'
  const ChamadaRecebidaView({
    super.key,
    required this.quemLiga,
    required this.jitsiUrl,
    this.origem = 'portaria',
  });

  @override
  State<ChamadaRecebidaView> createState() => _ChamadaRecebidaViewState();
}

class _ChamadaRecebidaViewState extends State<ChamadaRecebidaView> {
  @override
  void initState() {
    super.initState();
    ChamadaRing.instance.tocar();
  }

  @override
  void dispose() {
    ChamadaRing.instance.parar();
    super.dispose();
  }

  Future<void> _atender() async {
    await ChamadaRing.instance.parar();
    // Sala de áudio (sem vídeo).
    final url = '${widget.jitsiUrl}#config.startAudioOnly=true&config.startWithVideoMuted=true';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) Get.back();
  }

  Future<void> _recusar() async {
    await ChamadaRing.instance.parar();
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final subtitulo = widget.origem == 'condomino'
        ? 'Morador a ligar'
        : 'Portaria a ligar';
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
                  child: const Icon(Icons.call, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 28),
                Text(subtitulo,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  widget.quemLiga,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _botao(
                      cor: AppColors.danger,
                      icon: Icons.call_end,
                      label: 'Recusar',
                      onTap: _recusar,
                    ),
                    _botao(
                      cor: AppColors.success,
                      icon: Icons.call,
                      label: 'Atender',
                      onTap: _atender,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botao({
    required Color cor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: AppColors.textMain, fontSize: 14)),
      ],
    );
  }
}
