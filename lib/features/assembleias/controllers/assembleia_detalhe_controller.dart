import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/assembleia.dart';
import '../repositories/assembleia_repository.dart';

class AssembleiaDetalheController extends GetxController {
  final AssembleiaRepository _repo;
  final int assembleiaId;

  AssembleiaDetalheController({
    required this.assembleiaId,
    AssembleiaRepository? repo,
  }) : _repo = repo ?? AssembleiaRepository();

  final detalhe = Rxn<AssembleiaDetalhe>();
  final isLoading = false.obs;
  final isVotando = false.obs;
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
      detalhe.value = await _repo.obter(assembleiaId);
    } on DioException catch (e) {
      erro.value = e.response?.data?['message'] as String? ?? 'Erro.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> votar({required int pontoId, required String opcao}) async {
    if (isVotando.value) return false;
    isVotando.value = true;
    try {
      await _repo.votar(
        assembleiaId: assembleiaId,
        pontoId: pontoId,
        opcao: opcao,
      );
      Get.snackbar('Voto registado', 'O teu voto foi guardado.',
          snackPosition: SnackPosition.BOTTOM);
      await carregar();
      return true;
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        e.response?.data?['message'] as String? ?? 'Erro ao votar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isVotando.value = false;
    }
  }
}
