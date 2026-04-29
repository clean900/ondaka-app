import 'package:get/get.dart';

/// Controla o estado da bottom navigation do MainShell.
/// 0 = Início, 1 = Visitas, 2 = Avisos, 3 = Mais
class MainShellController extends GetxController {
  final tabIndex = 0.obs;

  void mudarTab(int index) {
    tabIndex.value = index;
  }
}
