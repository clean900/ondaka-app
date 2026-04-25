import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../shared/models/visita.dart';
import '../repositories/portaria_repository.dart';

/// Controller do ecrã "Quem está dentro agora".
///
/// Responsável por:
/// - Carregar lista de visitas activas (saiu_em IS NULL)
/// - Pull-to-refresh
/// - Marcar saída de uma visita específica
/// - Gerir estado de loading por visita (evita clicks duplicados)
class DentroAgoraController extends GetxController {
  final PortariaRepository _repository;

  DentroAgoraController({PortariaRepository? repository})
      : _repository = repository ?? PortariaRepository();

  // === State ===
  final visitas = <Visita>[].obs;
  final isLoading = false.obs;
  final errorMessage = Rx<String?>(null);

  /// IDs de visitas onde "marcar saída" está em progresso.
  /// Permite desactivar o botão só nesse item.
  final _saidaEmProgresso = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  /// Carrega lista de visitas dentro agora.
  Future<void> carregar() async {
    errorMessage.value = null;
    isLoading.value = true;

    try {
      final lista = await _repository.dentroAgora();
      visitas.value = lista;
    } on DioException catch (e) {
      errorMessage.value = _extrairErroDio(e);
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Marca saída de uma visita específica.
  ///
  /// Após sucesso, remove a visita da lista (já não está dentro).
  Future<bool> marcarSaida(int visitaId, {String? observacoes}) async {
    _saidaEmProgresso.add(visitaId);

    try {
      await _repository.registarSaida(visitaId, observacoes: observacoes);
      // Remove da lista local (UI actualiza imediatamente)
      visitas.removeWhere((v) => v.id == visitaId);
      return true;
    } on DioException catch (e) {
      Get.snackbar(
        'Erro ao marcar saída',
        _extrairErroDio(e),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível marcar a saída.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _saidaEmProgresso.remove(visitaId);
    }
  }

  /// Saber se uma visita está em progresso de marcação de saída.
  bool saidaEmProgresso(int visitaId) => _saidaEmProgresso.contains(visitaId);

  String _extrairErroDio(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('message')) {
        return data['message'] as String;
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Ligação lenta. Tente novamente.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Sem ligação à internet.';
    }

    return 'Erro ao carregar. Tente novamente.';
  }
}
