import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/dashboard_v2_widget.dart';

/// Tab "Início" do MainShell.
/// Mostra saudação + dashboard com carrossel + secções por categoria.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: FutureBuilder<Map<String, String?>>(
          future: StorageService.to.getUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data!;
            final nome = (user['name'] ?? 'Utilizador').split(' ').first;
            final saudacao = _saudacao();

            return RefreshIndicator(
              onRefresh: () async {
                // Refresh do dashboard será tratado pelo controller dele
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Saudação ===
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(text: '$saudacao, '),
                          TextSpan(
                            text: nome,
                            style: const TextStyle(
                              foreground: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitulo(user),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // === Dashboard novo ===
                    const DashboardV2Widget(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _saudacao() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 19) return 'Boa tarde';
    return 'Boa noite';
  }

  String _subtitulo(Map<String, String?> user) {
    final role = user['role'] ?? '';
    if (role == 'condomino') return 'Condómino · Paparazzi';
    return role.isEmpty ? '' : role;
  }
}
