import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Controller para listar tickets do user.
class MeusTicketsController extends GetxController {
  final TicketRepository _repo;

  MeusTicketsController({TicketRepository? repo})
      : _repo = repo ?? TicketRepository();

  final tickets = <Ticket>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final erro = RxnString();
  final estadoFiltro = Rxn<TicketEstado>();
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
      final page = await _repo.listar(estado: estadoFiltro.value);
      tickets.value = page.tickets;
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
      final page = await _repo.listar(
        estado: estadoFiltro.value,
        page: currentPage.value + 1,
      );
      tickets.addAll(page.tickets);
      currentPage.value = page.currentPage;
    } finally {
      isLoadingMore.value = false;
    }
  }

  void filtrarPorEstado(TicketEstado? estado) {
    estadoFiltro.value = estado;
    carregar();
  }

  String _erroDio(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada.';
    return e.response?.data?['message'] as String? ?? 'Erro ao carregar.';
  }
}
