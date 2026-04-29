import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/dashboard_v3_widget.dart';

/// Tab "Início" do MainShell.
/// Saudação com data + nome em gradient + dashboard v3.
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
            // TODO: ligar ao backend quando módulo Extracto existir.
            const condominio = 'Paparazzi';
            final saudacao = _saudacao();
            final dataStr = _dataExtenso();

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Data com asterisco decorativo ===
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.textFaint,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dataStr,
                          style: const TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // === Saudação com nome em gradient ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$saudacao, ',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                            height: 1.15,
                          ),
                        ),
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.cyan, AppColors.pink],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            nome,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // === Subtítulo com nome do condomínio em gradient ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'Aqui está o resumo do condomínio ',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.cyan, AppColors.pink],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: const Text(
                            condominio,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // === Dashboard v3 ===
                    const DashboardV3Widget(),
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

  String _dataExtenso() {
    final dt = DateTime.now();
    const dias = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo'
    ];
    const meses = [
      '',
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ];
    return '${dias[dt.weekday - 1]}, ${dt.day} de ${meses[dt.month]}';
  }
}
