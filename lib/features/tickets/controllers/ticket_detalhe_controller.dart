import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Controller para ver detalhe de um ticket + comentar/cancelar.
class TicketDetalheController extends GetxController {
  final TicketRepository _repo;
  final int ticketId;

  TicketDetalheController({required this.ticketId, TicketRepository? repo})
      : _repo = repo ?? TicketRepository();

  final ticket = Rxn<Ticket>();
  final isLoading = false.obs;
  final isComentando = false.obs;
  final isCancelando = false.obs;
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
      ticket.value = await _repo.obter(ticketId);
    } on DioException catch (e) {
      erro.value = _erroDio(e);
    } catch (e) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> comentar(String mensagem) async {
    if (isComentando.value || mensagem.trim().isEmpty) return false;
    isComentando.value = true;

    try {
      await _repo.comentar(ticketId, mensagem.trim());
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

  Future<bool> cancelar({String? motivo}) async {
    if (isCancelando.value) return false;
    isCancelando.value = true;

    try {
      await _repo.cancelar(ticketId, motivo: motivo);
      await carregar();
      Get.snackbar('Cancelado', 'Pedido cancelado com sucesso.');
      return true;
    } on DioException catch (e) {
      Get.snackbar('Erro', _erroDio(e),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isCancelando.value = false;
    }
  }


  /// Toggle apoio no pedido (apenas para tipo publico).
  Future<void> apoiar() async {
    final t = ticket.value;
    if (t == null || t.tipo != TicketTipo.publico) return;

    // Optimistic update
    final antes = t;
    ticket.value = t.copyWith(
      apoiadoPeloUser: !t.apoiadoPeloUser,
      totalApoios: t.apoiadoPeloUser
          ? (t.totalApoios - 1).clamp(0, 999999)
          : t.totalApoios + 1,
    );

    try {
      final result = await _repo.apoiar(ticketId);
      ticket.value = ticket.value!.copyWith(
        apoiadoPeloUser: result['apoiado'] as bool? ?? false,
        totalApoios: (result['total_apoios'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      // Reverte
      ticket.value = antes;
      Get.snackbar(
        'Erro',
        'Nao foi possivel apoiar o pedido.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _erroDio(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada.';
    if (e.response?.statusCode == 403) return 'Sem permissão.';
    return e.response?.data?['message'] as String? ?? 'Erro.';
  }
}
