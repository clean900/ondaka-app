import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme/app_colors.dart';

/// Mostra o [child] se o utilizador tem o [acesso]; caso contrario,
/// mostra uma mensagem de "sem acesso". Para nao-familiares mostra sempre o child.
class GateAcesso extends StatelessWidget {
  final String acesso;
  final Widget child;
  const GateAcesso({super.key, required this.acesso, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = AuthService.to;
      final pode = !auth.isFamiliar || auth.acessos.contains(acesso);
      if (pode) return child;
      return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Sem acesso a esta área',
                style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'O titular não lhe deu acesso a esta secção.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
          ),
        ),
      );
    });
  }
}
