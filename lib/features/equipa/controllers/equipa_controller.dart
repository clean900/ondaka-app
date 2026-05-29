import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/equipa_membro.dart';
import '../repositories/equipa_repository.dart';

/// Controller da equipa do condominio.
class EquipaController extends GetxController {
  final EquipaRepository _repo;

  EquipaController({EquipaRepository? repo})
      : _repo = repo ?? EquipaRepository();

  final membros = <EquipaMembro>[].obs;
  final isLoading = false.obs;
  final erro = RxnString();

  /// Total de users (excluindo empresas prestadoras).
  List<EquipaMembro> get users =>
      membros.where((m) => m.eUser).toList();

  /// Total de empresas prestadoras.
  List<EquipaMembro> get empresas =>
      membros.where((m) => m.eEmpresa).toList();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      membros.value = await _repo.listar();
    } on DioException catch (e) {
      erro.value = _erroDio(e);
    } catch (e) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  String _erroDio(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessao expirada.';
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Erro ao carregar equipa.';
  }
}
