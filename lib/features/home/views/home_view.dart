import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../nps/repositories/nps_repository.dart';
import '../../nps/views/nps_inquerito_view.dart';
import '../../publicidade/popup_publicidade.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/dashboard_financeiro_widget.dart';
import '../../../core/services/auth_service.dart';

/// Tab "Início" do MainShell.
/// Saudação com data + nome em gradient + dashboard v3.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Future<Map<String, String?>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = StorageService.to.getUser();
    _verificarNps();
    _verificarPopupPublicidade();
  }

  Future<void> _verificarPopupPublicidade() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await PopupPublicidade.verificarEMostrar(context);
  }

  Future<void> _verificarNps() async {
    // Espera a home assentar antes de mostrar o inquerito (nao-intrusivo).
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final pedidos = await NpsRepository().pedidosPendentes();
      if (!mounted || pedidos.isEmpty) return;
      // Mostra apenas o primeiro pedido pendente (um de cada vez).
      await Get.to(() => NpsInqueritoView(pedido: pedidos.first));
    } catch (_) {
      // Silencioso — NPS nunca deve atrapalhar a app.
    }
  }

  Future<void> _refresh() async {
    // 1. Refresh backend → storage
    await AuthService.to.fetchUser();
    // 2. Recarrega o Future do storage
    if (mounted) {
      setState(() {
        _userFuture = StorageService.to.getUser();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: FutureBuilder<Map<String, String?>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data!;
            final nome = (user['name'] ?? 'Utilizador').split(' ').first;
            final condominio = (user['condominio_nome']?.isNotEmpty ?? false)
                ? user['condominio_nome']!
                : 'o seu condomínio';
            final saudacao = _saudacao();
            final dataStr = _dataExtenso();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Data com asterisco decorativo ===
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/ondaka-logo.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
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
                          child: Text(
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

                    // === Dashboard Financeiro (Saldo + Pagar + Gráfico + Movimentos) ===
                    // Escondido para familiares (regra de ouro — so o titular ve dinheiro)
                    if (!AuthService.to.isFamiliar) const DashboardFinanceiroWidget(),
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
