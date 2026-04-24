import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/models/visita.dart';

/// Ecrã mostrado após validação bem-sucedida.
/// Guarda vê info do visitante autorizado.
class ValidacaoSucessoView extends StatelessWidget {
  final Visita visita;
  final VoidCallback onProximo;
  final VoidCallback onFechar;

  const ValidacaoSucessoView({
    super.key,
    required this.visita,
    required this.onProximo,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    final visitante = visita.visitante;
    final fraccao = visita.fraccao;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Checkmark grande
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 3),
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.success,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Entrada autorizada!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Visitante pode entrar',
            style: TextStyle(
              color: AppColors.successSoft,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          // Card info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.person,
                  label: 'Visitante',
                  value: visitante?.nome ?? '—',
                ),
                _divider(),
                _infoRow(
                  icon: Icons.home,
                  label: 'Fracção',
                  value: fraccao?.label ?? 'Fracção #${visita.fraccaoId}',
                ),
                _divider(),
                _infoRow(
                  icon: Icons.login,
                  label: 'Entrada registada',
                  value: _formatarHora(visita.entrouEm),
                ),
                _divider(),
                _infoRow(
                  icon: Icons.key,
                  label: 'Método',
                  value: visita.metodoValidacao.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botão próximo
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onProximo,
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              label: const Text(
                'PRÓXIMO VISITANTE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botão voltar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onFechar,
              child: const Text(
                'Voltar ao início',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cyanSoft, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        color: Colors.white.withValues(alpha: 0.08),
        height: 1,
      );

  String _formatarHora(DateTime dt) {
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final seg = dt.second.toString().padLeft(2, '0');
    return '$hora:$min:$seg';
  }
}
