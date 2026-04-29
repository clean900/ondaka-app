import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.person_add_outlined), text: 'Pré-aprovar'),
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'Minhas'),
            Tab(icon: Icon(Icons.history), text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const CriarPreAprovacaoView(),
          const MinhasPreAprovacoesView(),
          HistoricoVisitasView(
            fetch: PreAprovacaoRepository().historicoVisitas,
          ),
        ],
      ),
    );
  }
}
