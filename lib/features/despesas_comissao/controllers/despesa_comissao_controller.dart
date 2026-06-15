import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/despesa_pendente.dart';
import '../repositories/despesa_comissao_repository.dart';

/// Ecrã da comissão: lista de despesas pendentes + aprovar/recusar.
class DespesaComissaoController extends GetxController {
  final DespesaComissaoRepository _repo = DespesaComissaoRepository();

  final despesas = <DespesaPendente>[].obs;
  final isLoading = false.obs;
  final aProcessar = <int>{}.obs; // ids a aprovar/recusar
  final erro = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      despesas.assignAll(await _repo.listarPendentes());
    } catch (e) {
      erro.value = 'Não foi possível carregar as despesas pendentes.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> aprovar(DespesaPendente d) async {
    aProcessar.add(d.id);
    try {
      await _repo.aprovar(d.id);
      despesas.removeWhere((x) => x.id == d.id);
      Get.snackbar('Aprovada', 'Despesa aprovada com sucesso.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível aprovar a despesa.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      aProcessar.remove(d.id);
    }
  }

  Future<void> recusar(DespesaPendente d) async {
    final motivoCtrl = TextEditingController();
    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Recusar despesa'),
        content: TextField(
          controller: motivoCtrl,
          decoration: const InputDecoration(hintText: 'Motivo (opcional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Recusar')),
        ],
      ),
    );
    if (confirmar != true) return;

    aProcessar.add(d.id);
    try {
      await _repo.recusar(d.id, motivo: motivoCtrl.text.trim());
      despesas.removeWhere((x) => x.id == d.id);
      Get.snackbar('Recusada', 'Despesa recusada.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível recusar a despesa.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      aProcessar.remove(d.id);
    }
  }
}
