import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/aviso.dart';
import '../repositories/aviso_repository.dart';

class AvisoDetalheController extends GetxController {
  final AvisoRepository _repo;
  final int avisoId;

  AvisoDetalheController({required this.avisoId, AvisoRepository? repo})
      : _repo = repo ?? AvisoRepository();

  final aviso = Rxn<Aviso>();
  final isLoading = false.obs;
  final isComentando = false.obs;
  final isConfirmando = false.obs;
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
      aviso.value = await _repo.obter(avisoId);
      // Backend já marca como lido quando chamamos GET /avisos/{id}
    } on DioException catch (e) {
      erro.value = _erroDio(e);
    } catch (e) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> confirmarLeitura() async {
    if (isConfirmando.value) return false;
    isConfirmando.value = true;
    try {
      await _repo.marcarLido(avisoId, confirmar: true);
      Get.snackbar(
        'Confirmado',
        'Marcaste este aviso como lido e aceite.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await carregar();
      return true;
    } on DioException catch (e) {
      Get.snackbar('Erro', _erroDio(e),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isConfirmando.value = false;
    }
  }

  Future<bool> comentar(String mensagem, {int? parentId}) async {
    if (isComentando.value || mensagem.trim().isEmpty) return false;
    isComentando.value = true;
    try {
      await _repo.comentar(avisoId, mensagem.trim(), parentId: parentId);
      await carregar();
      return true;
    } on DioException catch (e) {
      Get.snackbar('Erro', _erroDio(e),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isComentando.value = false;
    }
  }

  String _erroDio(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada.';
    if (e.response?.statusCode == 403) return 'Sem permissão.';
    return e.response?.data?['message'] as String? ?? 'Erro.';
  }
}
