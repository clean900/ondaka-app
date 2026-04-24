import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/criar_pre_aprovacao_controller.dart';
import 'pre_aprovacao_sucesso_view.dart';

/// Ecrã para o condómino criar nova pré-aprovação.
class CriarPreAprovacaoView extends StatelessWidget {
  const CriarPreAprovacaoView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CriarPreAprovacaoController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Pré-aprovar visitante'),
        backgroundColor: AppColors.bgDark,
      ),
      body: Obx(() {
        // Se já criou com sucesso, mostra ecrã de sucesso
        if (controller.preAprovacaoCriada.value != null) {
          return PreAprovacaoSucessoView(
            preAprovacao: controller.preAprovacaoCriada.value!,
            onFechar: controller.fecharESair,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Nome
              _label('Nome do visitante'),
              const SizedBox(height: 6),
              TextField(
                controller: controller.nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Ex: João Silva'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              // Telefone
              _label('Telefone (para SMS)'),
              const SizedBox(height: 6),
              TextField(
                controller: controller.telefoneController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('923 000 000'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Validade
              _label('Válido até'),
              const SizedBox(height: 6),
              _atalhosDataView(controller),
              const SizedBox(height: 8),
              _dataEscolhida(context, controller),
              const SizedBox(height: 20),

              // Observações
              _label('Observações (opcional)'),
              const SizedBox(height: 6),
              TextField(
                controller: controller.observacoesController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Ex: chegará de carro'),
                maxLines: 2,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Erro
              if (controller.errorMessage.value != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Botão
              SizedBox(
                height: 52,
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'CRIAR PRÉ-APROVAÇÃO',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
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

  // === Helpers ===

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.cyan.withValues(alpha: 0.6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _atalhosDataView(CriarPreAprovacaoController controller) {
    final agora = DateTime.now();
    final hoje4h = agora.add(const Duration(hours: 4));
    final amanha20h = DateTime(agora.year, agora.month, agora.day + 1, 20, 0);
    final umaSemana = agora.add(const Duration(days: 7));

    return Wrap(
      spacing: 8,
      children: [
        _atalhoChip('Daqui a 4h', () => controller.definirValidadeAtalho(hoje4h)),
        _atalhoChip('Amanhã 20h', () => controller.definirValidadeAtalho(amanha20h)),
        _atalhoChip('Daqui a 1 semana', () => controller.definirValidadeAtalho(umaSemana)),
      ],
    );
  }

  Widget _atalhoChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _dataEscolhida(BuildContext context, CriarPreAprovacaoController controller) {
    return GestureDetector(
      onTap: () async {
        final agora = DateTime.now();
        final data = await showDatePicker(
          context: context,
          initialDate: controller.validaAte.value ?? agora.add(const Duration(days: 1)),
          firstDate: agora,
          lastDate: agora.add(const Duration(days: 90)),
        );
        if (data == null) return;

        if (!context.mounted) return;
        final hora = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(controller.validaAte.value ?? agora.add(const Duration(hours: 4))),
        );
        if (hora == null) return;

        controller.definirValidadeAtalho(
          DateTime(data.year, data.month, data.day, hora.hour, hora.minute),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.validaAte.value != null
                    ? _formatarData(controller.validaAte.value!)
                    : 'Tocar para escolher data e hora',
                style: TextStyle(
                  color: controller.validaAte.value != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final ano = dt.year.toString();
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$min';
  }
}
