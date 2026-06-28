import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../portaria/repositories/portaria_repository.dart' show AddonInativoException;
import '../models/pedido_autorizacao_bem.dart';
import '../repositories/autorizacoes_saida_repository.dart';

class AutorizacoesSaidaController extends GetxController {
  final AutorizacoesSaidaRepository _repo;

  AutorizacoesSaidaController({AutorizacoesSaidaRepository? repo})
      : _repo = repo ?? AutorizacoesSaidaRepository();

  final pedidos = <PedidoAutorizacaoBem>[].obs;
  final isLoading = false.obs;
  final addonInativo = false.obs;
  final erro = Rx<String?>(null);
  final _aProcessar = <int>{}.obs;

  bool emProgresso(int itemId) => _aProcessar.contains(itemId);

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      pedidos.value = await _repo.pendentes();
    } on AddonInativoException {
      addonInativo.value = true;
    } on DioException catch (e) {
      erro.value = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Erro ao carregar.')
          : 'Erro ao carregar.';
    } catch (_) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> responder(int itemId, {required bool aprovar}) async {
    _aProcessar.add(itemId);
    try {
      await _repo.autorizar(itemId, aprovar: aprovar);
      pedidos.removeWhere((p) => p.itemId == itemId);
      Get.snackbar(
        aprovar ? 'Saída autorizada' : 'Saída recusada',
        aprovar ? 'O bem pode sair.' : 'O bem deve ser retido na portaria.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Não foi possível responder.')
          : 'Não foi possível responder.';
      Get.snackbar('Erro', msg, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível responder.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      _aProcessar.remove(itemId);
    }
  }
}
