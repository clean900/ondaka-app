import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/pre_aprovacao_repository.dart';
import 'criar_pre_aprovacao_view.dart';
import 'historico_visitas_view.dart';
import 'minhas_pre_aprovacoes_view.dart';

/// Shell da tab "Visitas" — TabBar com 3 sub-views:
/// Pré-aprovar | Minhas | Histórico
class VisitasShellView extends StatelessWidget {
  const VisitasShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1, // arranca em "Minhas" (mais usado)
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          title: const Text('Visitas'),
          bottom: const TabBar(
            indicatorColor: AppColors.cyan,
            labelColor: AppColors.cyan,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(icon: Icon(Icons.person_add_outlined), text: 'Pré-aprovar'),
              Tab(icon: Icon(Icons.list_alt_outlined), text: 'Minhas'),
              Tab(icon: Icon(Icons.history), text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const CriarPreAprovacaoView(),
            const MinhasPreAprovacoesView(),
            HistoricoVisitasView(
              fetch: PreAprovacaoRepository().historicoVisitas,
            ),
          ],
        ),
      ),
    );
  }
}
