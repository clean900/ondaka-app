import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../acordos/models/acordo.dart';
import '../../acordos/views/acesso_limitado_view.dart';
import '../../dashboard/repositories/dashboard_repository.dart';

/// Controla o estado da bottom navigation do MainShell.
/// 0 = Início, 1 = Visitas, 2 = Avisos, 3 = Suporte, 4 = Mais
class MainShellController extends GetxController with WidgetsBindingObserver {
  final tabIndex = 0.obs;

  final avisosNaoLidos = 0.obs;

  final DashboardRepository _dashboardRepo = DashboardRepository();

  // evita reentrar no ecrã de bloqueio se já lá estamos
  bool _bloqueioAberto = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    carregarAvisosNaoLidos();
    verificarAcesso();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ao voltar de background -> reverifica
    if (state == AppLifecycleState.resumed) {
      verificarAcesso();
    }
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
    } catch (_) {}
  }

  /// Verifica se o condómino está em modo limitado. Se sim, redireciona
  /// para o ecrã de acesso limitado (intercepta a navegação normal).
  Future<void> verificarAcesso() async {
    if (_bloqueioAberto) return;
    try {
      final LimitacaoInfo? info = await _dashboardRepo.estadoAcesso();
      if (info != null && info.limitado) {
        _bloqueioAberto = true;
        await Get.to(() => AcessoLimitadoView(info: info));
        _bloqueioAberto = false;
        // ao fechar o ecrã, reverifica (pode ter proposto acordo entretanto)
        verificarAcesso();
      }
    } catch (_) {
      // silencioso: falha de rede não bloqueia a app
    }
  }
}
