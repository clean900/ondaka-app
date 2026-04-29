import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class DashboardController extends GetxController {
  final DashboardRepository _repo;

  DashboardController({DashboardRepository? repo})
      : _repo = repo ?? DashboardRepository();

  final dashboard = Rxn<DashboardData>();
  final isLoading = false.obs;
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
      dashboard.value = await _repo.obterCondomino();
    } on DioException catch (e) {
      erro.value =
          e.response?.data?['message'] as String? ?? 'Erro ao carregar dashboard.';
    } finally {
      isLoading.value = false;
    }
  }
}
