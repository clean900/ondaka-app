import 'package:get/get.dart';

import '../models/relatorio_financeiro.dart';
import '../repositories/transparencia_repository.dart';

/// Controller da transparência financeira do condomínio (condómino).
class TransparenciaController extends GetxController {
  final _repo = TransparenciaRepository();

  final relatorio = Rxn<RelatorioFinanceiro>();
  final isLoading = false.obs;
  final erro = RxnString();
  final meses = 12.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      relatorio.value = await _repo.obter(meses: meses.value);
    } catch (e) {
      erro.value = 'Não foi possível carregar o relatório financeiro.';
    } finally {
      isLoading.value = false;
    }
  }

  void mudarPeriodo(int novosMeses) {
    if (meses.value == novosMeses) return;
    meses.value = novosMeses;
    carregar();
  }
}
