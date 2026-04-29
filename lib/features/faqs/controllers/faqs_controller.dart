import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/faq.dart';
import '../repositories/faq_repository.dart';

class FaqsController extends GetxController {
  final FaqRepository _repo;

  FaqsController({FaqRepository? repo}) : _repo = repo ?? FaqRepository();

  // Estado base
  final _todas = <Faq>[].obs;
  final isLoading = false.obs;
  final erro = RxnString();

  // Pesquisa
  final query = ''.obs;

  // Cards expandidos (set de IDs)
  final _expandidos = <int>{}.obs;

  /// Lista filtrada com base na query actual.
  /// Filtragem local: rápida, sem hit à API a cada tecla.
  List<Faq> get faqs {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return _todas;
    return _todas.where((f) {
      return f.pergunta.toLowerCase().contains(q) ||
          f.resposta.toLowerCase().contains(q) ||
          f.categoria.toLowerCase().contains(q);
    }).toList();
  }

  /// Indicação se está em modo de pesquisa activa.
  bool get pesquisando => query.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      _todas.value = await _repo.listar();
    } on DioException catch (e) {
      erro.value =
          e.response?.data?['message'] as String? ?? 'Erro ao carregar.';
    } finally {
      isLoading.value = false;
    }
  }

  void atualizarQuery(String novo) {
    query.value = novo;
  }

  void limparQuery() {
    query.value = '';
  }

  // Expansão dos cards
  bool estaExpandida(int faqId) => _expandidos.contains(faqId);

  void alternarExpansao(int faqId) {
    if (_expandidos.contains(faqId)) {
      _expandidos.remove(faqId);
    } else {
      _expandidos.add(faqId);
    }
    _expandidos.refresh();
  }
}
