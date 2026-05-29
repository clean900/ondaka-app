import 'package:get/get.dart';
import '../models/checklist_modelo.dart';
import '../repositories/checklist_repository.dart';

class ChecklistController extends GetxController {
  final ChecklistRepository _repo = ChecklistRepository();

  final modelos = <ChecklistModelo>[].obs;
  final aCarregar = false.obs;
  final erro = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    aCarregar.value = true;
    erro.value = null;
    try {
      modelos.value = await _repo.disponiveis();
    } catch (e) {
      erro.value = 'Não foi possível carregar as checklists.';
    } finally {
      aCarregar.value = false;
    }
  }

  Future<bool> submeter({
    required int modeloId,
    required List<Map<String, dynamic>> respostas,
    String? observacoes,
  }) async {
    try {
      return await _repo.submeter(modeloId: modeloId, respostas: respostas, observacoes: observacoes);
    } catch (e) {
      return false;
    }
  }
}
