import 'package:get/get.dart';

import '../../dashboard/repositories/dashboard_repository.dart';

/// Controla o estado da bottom navigation do MainShell.
/// 0 = Início, 1 = Visitas, 2 = Avisos, 3 = Suporte, 4 = Mais
class MainShellController extends GetxController {
  final tabIndex = 0.obs;

  final avisosNaoLidos = 0.obs;

  final DashboardRepository _dashboardRepo = DashboardRepository();

  @override
  void onInit() {
    super.onInit();
    carregarAvisosNaoLidos();
  }

  void mudarTab(int index) {
    tabIndex.value = index;
    if (index != 2) {
      carregarAvisosNaoLidos();
    }
  }

  Future<void> carregarAvisosNaoLidos() async {
    try {
      final data = await _dashboardRepo.obterCondomino();
      avisosNaoLidos.value = data.avisosNaoLidos;
    } catch (_) {
    }
  }
}
