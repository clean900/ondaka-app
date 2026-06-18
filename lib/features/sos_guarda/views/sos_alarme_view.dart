import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/sos_sirene.dart';
import 'sos_guarda_lista_view.dart';

/// Ecrã de alarme SOS — full-screen vermelho a piscar com sirene em loop.
/// Aberto assim que chega um SOS (mesmo com a app fechada, via full-screen
/// intent). Pisca e toca até o guarda carregar em ATENDER (primeira
/// intervenção), que silencia a sirene e abre a lista de alertas.
class SosAlarmeView extends StatefulWidget {
  final String tipoLabel;
  final String? local;
  final int? sosId;

  const SosAlarmeView({
    super.key,
    required this.tipoLabel,
    this.local,
    this.sosId,
  });

  @override
  State<SosAlarmeView> createState() => _SosAlarmeViewState();
}

class _SosAlarmeViewState extends State<SosAlarmeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
    // Garante a sirene a tocar em loop enquanto o alarme está aberto.
    SosSirene.instance.tocar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _atender() {
    SosSirene.instance.parar();
    Get.off(() => const SosGuardaListaView());
  }

  @override
  Widget build(BuildContext context) {
    // Bloqueia o "back" — o guarda tem de ATENDER para sair do alarme.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final cor = Color.lerp(
              const Color(0xFF6B0F0F),
              const Color(0xFFEF4444),
              _ctrl.value,
            )!;
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: cor,
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 130,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.tipoLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.local != null && widget.local!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '📍 ${widget.local!}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'EMERGÊNCIA RECEBIDA',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 68,
                        child: ElevatedButton.icon(
                          onPressed: _atender,
                          icon: const Icon(Icons.shield, size: 26),
                          label: const Text(
                            'ATENDER',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFB91C1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
