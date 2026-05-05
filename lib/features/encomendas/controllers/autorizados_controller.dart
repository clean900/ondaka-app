import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/fraccao_autorizado.dart';
import '../repositories/autorizado_repository.dart';

class AutorizadosController extends GetxController {
  final AutorizadoRepository _repo;

  AutorizadosController({AutorizadoRepository? repo})
      : _repo = repo ?? AutorizadoRepository();

  final autorizados = <FraccaoAutorizado>[].obs;
  final isLoading = false.obs;
  final erro = RxnString();
  final _apagandoIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      autorizados.value = await _repo.listar();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> criar({
    required String nomeCompleto,
    required String relacao,
    String? biPassport,
    String? telefone,
  }) async {
    try {
      final novo = await _repo.criar(
        nomeCompleto: nomeCompleto,
        relacao: relacao,
        biPassport: biPassport,
        telefone: telefone,
      );
      autorizados.insert(0, novo);
      Get.snackbar('Adicionado', '$nomeCompleto autorizado.',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } on DioException catch (e) {
      Get.snackbar('Erro', _extrairErro(e),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível adicionar.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  bool isApagando(int id) => _apagandoIds.contains(id);

  Future<bool> apagar(int id) async {
    if (_apagandoIds.contains(id)) return false;
    _apagandoIds.add(id);
    try {
      await _repo.apagar(id);
      autorizados.removeWhere((a) => a.id == id);
      return true;
    } on DioException catch (e) {
      Get.snackbar('Erro', _extrairErro(e),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível remover.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _apagandoIds.remove(id);
    }
  }

  String _extrairErro(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Erro de ligação.';
  }
}
