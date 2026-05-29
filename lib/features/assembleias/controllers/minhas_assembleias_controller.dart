import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/assembleia.dart';
import '../repositories/assembleia_repository.dart';

class MinhasAssembleiasController extends GetxController {
  final AssembleiaRepository _repo;

  MinhasAssembleiasController({AssembleiaRepository? repo})
      : _repo = repo ?? AssembleiaRepository();

  final assembleias = <Assembleia>[].obs;
  final isLoading = false.obs;
  final addonActivo = true.obs;
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
      assembleias.value = await _repo.listar();
      addonActivo.value = true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        addonActivo.value = false;
      } else {
        erro.value = e.response?.data?['message'] as String? ?? 'Erro ao carregar.';
      }
    } finally {
      isLoading.value = false;
    }
  }
}
