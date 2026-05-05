import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/encomenda.dart';
import '../repositories/encomenda_repository.dart';

/// Controller para listar e gerir encomendas do condómino.
/// Suporta filtro por estado para diferentes sub-tabs.
class MinhasEncomendasController extends GetxController {
  final EncomendaRepository _repo;

  MinhasEncomendasController({EncomendaRepository? repo})
      : _repo = repo ?? EncomendaRepository();

  // Estado global (sem filtro)
  final encomendas = <Encomenda>[].obs;
  final isLoading = false.obs;
  final erro = RxnString();
  final _cancelandoIds = <int>{}.obs;

  // Estado para sub-tabs específicas
  final aguardamChegada = <Encomenda>[].obs;
  final naPortaria = <Encomenda>[].obs;
  final historico = <Encomenda>[].obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  /// Carrega tudo de uma vez e separa por estado nas listas das sub-tabs.
  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;

    try {
      final lista = await _repo.listar();
      encomendas.value = lista;
      _separarPorEstado(lista);
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (e) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  void _separarPorEstado(List<Encomenda> lista) {
    aguardamChegada.value =
        lista.where((e) => e.estado == 'aguarda_chegada').toList();
    naPortaria.value = lista
        .where((e) =>
            e.estado == 'aguarda_levantamento' || e.estado == 'multa_aplicada')
        .toList();
    historico.value = lista
        .where((e) => e.estado == 'entregue' || e.estado == 'cancelada')
        .toList();
  }

  bool isCancelando(int id) => _cancelandoIds.contains(id);

  /// Cancela um pré-anúncio (só funciona se estado=aguarda_chegada).
  Future<bool> cancelar(int id) async {
    if (_cancelandoIds.contains(id)) return false;
    _cancelandoIds.add(id);

    try {
      final cancelada = await _repo.cancelar(id);

      // Actualizar listas
      final idx = encomendas.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        encomendas[idx] = cancelada;
      }
      _separarPorEstado(encomendas);

      Get.snackbar(
        'Cancelada',
        'Pré-anúncio cancelado.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on DioException catch (e) {
      Get.snackbar('Erro', _extrairErro(e),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível cancelar.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _cancelandoIds.remove(id);
    }
  }

  String _extrairErro(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Erro de ligação. Tenta novamente.';
  }
}
