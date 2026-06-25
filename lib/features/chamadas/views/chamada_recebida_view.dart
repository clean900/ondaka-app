import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Ecrã full-screen de chamada recebida (estilo SOS): toca em loop.
/// Atender → arranca a chamada WebRTC; Recusar → fecha.
/// O som e a navegação são controlados pelo WebrtcCallService.
class ChamadaRecebidaView extends StatelessWidget {
  final String quemLiga;
  final String origem; // papel de quem liga: portaria / condomino / gestor
  final VoidCallback onAtender;
  final VoidCallback onRecusar;
  const ChamadaRecebidaView({
    super.key,
    required this.quemLiga,
    required this.onAtender,
    required this.onRecusar,
    this.origem = 'portaria',
  });

  String get _subtitulo {
    switch (origem) {
      case 'condomino':
        return 'Morador a ligar';
      case 'gestor':
        return 'Gestor a ligar';
      default:
        return 'Portaria a ligar';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text(_subtitulo,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  quemLiga,
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
                      onTap: onRecusar,
                    ),
                    _botao(
                      cor: AppColors.success,
                      icon: Icons.call,
                      label: 'Atender',
                      onTap: onAtender,
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
