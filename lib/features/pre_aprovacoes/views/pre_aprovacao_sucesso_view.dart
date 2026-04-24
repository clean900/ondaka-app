import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../models/pre_aprovacao.dart';

/// Ecrã de confirmação após criar pré-aprovação.
///
/// Mostra OTP em destaque, info do visitante, e confirmação do SMS.
class PreAprovacaoSucessoView extends StatelessWidget {
  final PreAprovacao preAprovacao;
  final VoidCallback onFechar;

  const PreAprovacaoSucessoView({
    super.key,
    required this.preAprovacao,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Checkmark success
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyan, width: 2),
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.cyan,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Pré-aprovação criada!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Para: ${preAprovacao.nomeVisitante}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),

          // OTP grande
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'CÓDIGO DE ENTRADA',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  preAprovacao.otpCode,
                  style: const TextStyle(
                    color: Color(0xFF001218),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: preAprovacao.otpCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código copiado!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16, color: AppColors.cyanSoft),
            label: const Text(
              'Copiar código',
              style: TextStyle(color: AppColors.cyanSoft),
            ),
          ),
          const SizedBox(height: 24),

          // Info cards
          _infoCard(
            icon: Icons.sms_outlined,
            title: preAprovacao.smsEnviado
                ? 'SMS enviado ao visitante'
                : 'SMS não foi enviado',
            subtitle: preAprovacao.smsEnviado
                ? '${preAprovacao.telefoneVisitante}\nO visitante já tem o código.'
                : 'Partilhe o código por WhatsApp ou voz.',
            color: preAprovacao.smsEnviado ? AppColors.cyan : Colors.amber,
          ),
          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.schedule,
            title: 'Válido até',
            subtitle: _formatarData(preAprovacao.validaAte),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onFechar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'FECHAR',
                style: TextStyle(
                  fontSize: 14,
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

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final accent = color ?? AppColors.cyan;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
