import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/pre_aprovacao.dart';
import '../repositories/pre_aprovacao_repository.dart';

/// Controller para listar e gerir pré-aprovações do condomino.
class MinhasPreAprovacoesController extends GetxController {
  final PreAprovacaoRepository _repo;

  MinhasPreAprovacoesController({PreAprovacaoRepository? repo})
      : _repo = repo ?? PreAprovacaoRepository();

  // Estado
  final preAprovacoes = <PreAprovacao>[].obs;
  final isLoading = false.obs;
  final erro = RxnString();
  final estadoFiltro = Rxn<EstadoPreAprovacao>();
  final _cancelandoIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  /// Carrega lista (com filtro actual).
  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;

    try {
      final lista = await _repo.listar(
        estado: estadoFiltro.value?.name,
      );
      preAprovacoes.value = lista;
    } on DioException catch (e) {
      erro.value = _extrairErroDio(e);
    } catch (e) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Aplica filtro de estado e recarrega.
  void filtrarPorEstado(EstadoPreAprovacao? estado) {
    estadoFiltro.value = estado;
    carregar();
  }

  /// Cancela uma pré-aprovação pendente.
  /// Faz optimistic update — remove imediatamente da lista.
  Future<void> cancelar(int id) async {
    if (_cancelandoIds.contains(id)) return;
    _cancelandoIds.add(id);

    try {
      final cancelada = await _repo.cancelar(id);

      // Actualizar item na lista (mantém ordenação, só muda estado)
      final index = preAprovacoes.indexWhere((p) => p.id == id);
      if (index != -1) {
        preAprovacoes[index] = cancelada;
        preAprovacoes.refresh();
      }

      Get.snackbar(
        'Cancelada',
        'Pré-aprovação cancelada com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException catch (e) {
      Get.snackbar(
        'Erro ao cancelar',
        _extrairErroDio(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _cancelandoIds.remove(id);
    }
  }

  bool isCancelando(int id) => _cancelandoIds.contains(id);

  String _extrairErroDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Sem ligação. Verifique a sua internet.';
    }
    if (e.response?.statusCode == 401) {
      return 'Sessão expirada. Por favor faça login novamente.';
    }
    if (e.response?.statusCode == 403) {
      return 'Sem permissão.';
    }
    final msg = e.response?.data?['message'] as String?;
    return msg ?? 'Erro ao processar pedido.';
  }
}
