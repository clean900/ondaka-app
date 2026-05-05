import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/minhas_encomendas_controller.dart';
import 'aguardam_chegada_view.dart';
import 'autorizados_view.dart';
import 'historico_encomendas_view.dart';
import 'na_portaria_view.dart';

/// Shell da tab "Encomendas" — TabBar com 3 sub-views:
/// Aguardam | Na portaria | Histórico.
class EncomendasShellView extends StatefulWidget {
  const EncomendasShellView({super.key});

  @override
  State<EncomendasShellView> createState() => _EncomendasShellViewState();
}

class _EncomendasShellViewState extends State<EncomendasShellView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 1, // Arranca em "Na portaria" — mais relevante
    );

    // Garante que o controller está disponível para as 3 sub-views
    if (!Get.isRegistered<MinhasEncomendasController>()) {
      Get.put(MinhasEncomendasController(), permanent: false);
    }
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
        title: const Text('Encomendas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.schedule_outlined), text: 'Aguardam'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Na portaria'),
            Tab(icon: Icon(Icons.history), text: 'Histórico'),
            Tab(icon: Icon(Icons.people_outline), text: 'Autorizados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AguardamChegadaView(),
          NaPortariaView(),
          HistoricoEncomendasView(),
          AutorizadosView(),
        ],
      ),
    );
  }
}
