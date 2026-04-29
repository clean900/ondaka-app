import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/ordem.dart';
import '../repositories/ordem_repository.dart';

class MinhasOrdensController extends GetxController {
  final OrdemRepository _repo;

  MinhasOrdensController({OrdemRepository? repo})
      : _repo = repo ?? OrdemRepository();

  final ordens = <Ordem>[].obs;
  final isLoading = false.obs;
  final erro = RxnString();
  final estadoFiltro = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      print("[ORDENS] A chamar API...");
      final page = await _repo.listar(estado: estadoFiltro.value);
      print("[ORDENS] Recebidas " + page.ordens.length.toString() + " ordens");
      ordens.value = page.ordens;
    } on DioException catch (e) {
      print("[ORDENS] Erro Dio: " + e.toString());
      print("[ORDENS] Response: " + (e.response?.data?.toString() ?? "null"));
      erro.value = e.response?.data?['message'] as String? ?? 'Erro ao carregar.';
    } finally {
      isLoading.value = false;
    }
  }

  void filtrar(String? estado) {
    estadoFiltro.value = estado;
    carregar();
  }
}
