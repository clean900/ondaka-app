import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../shared/models/historico_visitas_page.dart';
import '../../../shared/models/visita.dart';

/// Tipo da função que carrega histórico paginado.
///
/// Permite ao controller ser usado por condomino (via PreAprovacaoRepository)
/// ou guarda (via PortariaRepository) — basta passar o método correspondente.
typedef FetchHistoricoFn = Future<HistoricoVisitasPage> Function({
  DateTime? desde,
  DateTime? ate,
  String? nome,
  MetodoValidacao? metodo,
  int page,
  int perPage,
});

/// Controller genérico para listar histórico de visitas.
///
/// Suporta filtros opcionais (data, nome, método) e paginação.
/// Recebe uma callback de fetch — não conhece o repository directamente.
class HistoricoVisitasController extends GetxController {
  final FetchHistoricoFn _fetch;

  HistoricoVisitasController({required FetchHistoricoFn fetch}) : _fetch = fetch;

  // Estado
  final visitas = <Visita>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final erro = RxnString();
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final total = 0.obs;

  // Filtros
  final desde = Rxn<DateTime>();
  final ate = Rxn<DateTime>();
  final nomeFiltro = ''.obs;
  final metodoFiltro = Rxn<MetodoValidacao>();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;

    try {
      final page = await _fetch(
        desde: desde.value,
        ate: ate.value,
        nome: nomeFiltro.value.isNotEmpty ? nomeFiltro.value : null,
        metodo: metodoFiltro.value,
        page: 1,
        perPage: 20,
      );

      visitas.value = page.visitas;
      currentPage.value = page.currentPage;
      lastPage.value = page.lastPage;
      total.value = page.total;
    } on DioException catch (e) {
      erro.value = _extrairErroDio(e);
    } catch (e) {
      erro.value = 'Erro inesperado. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> carregarMais() async {
    if (isLoadingMore.value) return;
    if (currentPage.value >= lastPage.value) return;

    isLoadingMore.value = true;

    try {
      final page = await _fetch(
        desde: desde.value,
        ate: ate.value,
        nome: nomeFiltro.value.isNotEmpty ? nomeFiltro.value : null,
        metodo: metodoFiltro.value,
        page: currentPage.value + 1,
        perPage: 20,
      );

      visitas.addAll(page.visitas);
      currentPage.value = page.currentPage;
      lastPage.value = page.lastPage;
    } on DioException catch (e) {
      Get.snackbar('Erro', _extrairErroDio(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void aplicarFiltros({
    DateTime? novoDesde,
    DateTime? novoAte,
    String? novoNome,
    MetodoValidacao? novoMetodo,
  }) {
    desde.value = novoDesde;
    ate.value = novoAte;
    nomeFiltro.value = novoNome ?? '';
    metodoFiltro.value = novoMetodo;
    carregar();
  }

  void limparFiltros() {
    desde.value = null;
    ate.value = null;
    nomeFiltro.value = '';
    metodoFiltro.value = null;
    carregar();
  }

  bool get temFiltrosActivos =>
      desde.value != null ||
      ate.value != null ||
      nomeFiltro.value.isNotEmpty ||
      metodoFiltro.value != null;

  String _extrairErroDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Sem ligação. Verifique a sua internet.';
    }
    if (e.response?.statusCode == 401) {
      return 'Sessão expirada. Por favor faça login novamente.';
    }
    if (e.response?.statusCode == 403) {
      return 'Sem permissão para ver este histórico.';
    }
    final msg = e.response?.data?['message'] as String?;
    return msg ?? 'Erro ao carregar histórico.';
  }
}
