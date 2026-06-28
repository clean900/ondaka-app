import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/validar_otp_controller.dart';
import 'scan_qr_view.dart';
import 'validacao_sucesso_view.dart';

class ValidarOtpView extends StatelessWidget {
  const ValidarOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ValidarOtpController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Validar código'),
        backgroundColor: AppColors.bgDark,
      ),
      body: Obx(() {
        if (controller.visitaAutorizada.value != null) {
          final alerta = controller.listaNegraAlerta.value;
          return Column(
            children: [
              if (controller.offline.value)
                Container(
                  width: double.infinity,
                  color: AppColors.warning.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off, color: AppColors.warningSoft, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Entrada validada OFFLINE — será sincronizada quando houver rede.',
                            style: TextStyle(color: AppColors.warningSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              if (alerta != null) _bannerListaNegra(alerta),
              Expanded(
                child: ValidacaoSucessoView(
                  visita: controller.visitaAutorizada.value!,
                  onProximo: controller.proximaValidacao,
                  onFechar: controller.voltar,
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.password,
                color: AppColors.cyanSoft,
                size: 56,
              ),
              const SizedBox(height: 16),

              const Text(
                'Introduza o código',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'O visitante recebeu um código de 6 dígitos por SMS.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 36),

              TextField(
                controller: controller.otpController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.cyan.withValues(alpha: 0.6), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 24),

              if (controller.errorMessage.value != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submeter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'VALIDAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Alternativa: ler o QR do visitante com a câmara
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          final token = await Navigator.of(context).push<String>(
                            MaterialPageRoute(
                              builder: (_) => const ScanQrView(),
                            ),
                          );
                          if (token != null && token.isNotEmpty) {
                            controller.validarQrToken(token);
                          }
                        },
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.cyan),
                  label: const Text(
                    'LER QR DO VISITANTE',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Banner vermelho de alerta: o visitante consta na Lista Negra.
  Widget _bannerListaNegra(Map<String, dynamic> alerta) {
    final motivo = alerta['motivo']?.toString();
    return Container(
      width: double.infinity,
      color: const Color(0xFFB91C1C),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          const Icon(Icons.gpp_bad, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ LISTA NEGRA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alerta['mensagem']?.toString() ??
                      'Este visitante consta na lista negra do condomínio.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                if (motivo != null && motivo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Motivo: $motivo',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
