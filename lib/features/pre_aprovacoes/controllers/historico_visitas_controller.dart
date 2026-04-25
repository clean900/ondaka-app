import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../shared/models/visita.dart';
import '../repositories/pre_aprovacao_repository.dart';

/// Controller para listar histórico de visitas das fracções do condomino.
///
/// Suporta filtros opcionais (data, nome, método) e paginação.
class HistoricoVisitasController extends GetxController {
  final PreAprovacaoRepository _repo;

  HistoricoVisitasController({PreAprovacaoRepository? repo})
      : _repo = repo ?? PreAprovacaoRepository();

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

  /// Carrega 1ª página com filtros actuais.
  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;

    try {
      final page = await _repo.historicoVisitas(
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

  /// Carrega próxima página (scroll infinito).
  Future<void> carregarMais() async {
    if (isLoadingMore.value) return;
    if (currentPage.value >= lastPage.value) return;

    isLoadingMore.value = true;

    try {
      final page = await _repo.historicoVisitas(
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

  /// Aplica filtros e recarrega.
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

  /// Limpa todos os filtros.
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
