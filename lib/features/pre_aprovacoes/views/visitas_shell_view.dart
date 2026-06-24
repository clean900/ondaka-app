import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../chamadas/repositories/chamada_repository.dart';
import '../../passes/views/passes_view.dart';
import '../repositories/pre_aprovacao_repository.dart';
import 'criar_pre_aprovacao_view.dart';
import 'historico_visitas_view.dart';
import 'minhas_pre_aprovacoes_view.dart';

/// Shell da tab "Visitas" — TabBar com 3 sub-views:
/// Pré-aprovar | Minhas | Histórico.
/// Arranca em "Minhas" (mais usado pelo condómino).
class VisitasShellView extends StatefulWidget {
  const VisitasShellView({super.key});

  @override
  State<VisitasShellView> createState() => _VisitasShellViewState();
}

class _VisitasShellViewState extends State<VisitasShellView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _aLigar = false;

  Future<void> _ligarPortaria() async {
    setState(() => _aLigar = true);
    try {
      final url = await ChamadaRepository().ligarPortaria();
      final audio = '$url#config.startAudioOnly=true&config.startWithVideoMuted=true';
      final uri = Uri.parse(audio);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } on Object catch (e) {
      final msg = e.toString().contains('422')
          ? 'Não há portaria de serviço disponível.'
          : 'Não foi possível ligar à portaria.';
      Get.snackbar('Chamada', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _aLigar = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 1, // arranca em "Minhas"
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Visitas'),
        actions: [
          IconButton(
            tooltip: 'Ligar à portaria',
            icon: _aLigar
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan))
                : const Icon(Icons.call, color: AppColors.cyan),
            onPressed: _aLigar ? null : _ligarPortaria,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.person_add_outlined), text: 'Pré-aprovar'),
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'Minhas'),
            Tab(icon: Icon(Icons.badge_outlined), text: 'Passes'),
            Tab(icon: Icon(Icons.history), text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const CriarPreAprovacaoView(),
          const MinhasPreAprovacoesView(),
          const PassesView(),
          HistoricoVisitasView(
            fetch: PreAprovacaoRepository().historicoVisitas,
          ),
        ],
      ),
    );
  }
}
