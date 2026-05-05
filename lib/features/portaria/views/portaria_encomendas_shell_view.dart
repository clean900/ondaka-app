import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/portaria_encomendas_controller.dart';
import 'aguarda_chegada_portaria_view.dart';
import 'historico_portaria_view.dart';
import 'na_portaria_view.dart';
import 'registar_encomenda_manual_view.dart';

/// Shell de encomendas do perfil PORTARIA com 2 sub-tabs:
/// - Aguardam (pré-anunciadas, à espera de chegar)
/// - Portaria (chegaram, à espera de levantamento)
///
/// FAB "+ Registar manual" para Fluxo A (encomendas sem aviso prévio).
class PortariaEncomendasShellView extends StatelessWidget {
  const PortariaEncomendasShellView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PortariaEncomendasController(), permanent: false);

    return DefaultTabController(
      length: 3,
      initialIndex: 1, // Arranca em "Portaria" — uso mais comum do guarda
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          title: const Text('Encomendas'),
          backgroundColor: AppColors.bgDark,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.schedule_outlined), text: 'Aguardam'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Portaria'),
              Tab(icon: Icon(Icons.history), text: 'Histórico'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AguardaChegadaPortariaView(),
            NaPortariaView(),
            HistoricoPortariaView(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const RegistarEncomendaManualView()),
          icon: const Icon(Icons.add),
          label: const Text('Registar manual'),
          backgroundColor: AppColors.cyan,
          foregroundColor: const Color(0xFF001218),
        ),
      ),
    );
  }
}
