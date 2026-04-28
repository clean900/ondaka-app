import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/aviso.dart';
import '../repositories/aviso_repository.dart';

class MeusAvisosController extends GetxController {
  final AvisoRepository _repo;

  MeusAvisosController({AvisoRepository? repo})
      : _repo = repo ?? AvisoRepository();

  final avisos = <Aviso>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final erro = RxnString();
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final total = 0.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      final page = await _repo.listar();
      avisos.value = page.avisos;
      currentPage.value = page.currentPage;
      lastPage.value = page.lastPage;
      total.value = page.total;
    } on DioException catch (e) {
      erro.value = _erroDio(e);
    } catch (e) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> carregarMais() async {
    if (isLoadingMore.value || currentPage.value >= lastPage.value) return;
    isLoadingMore.value = true;
    try {
      final page = await _repo.listar(page: currentPage.value + 1);
      avisos.addAll(page.avisos);
      currentPage.value = page.currentPage;
    } finally {
      isLoadingMore.value = false;
    }
  }

  String _erroDio(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada.';
    return e.response?.data?['message'] as String? ?? 'Erro ao carregar.';
  }
}
