import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/checklist_modelo.dart';
import '../repositories/checklist_repository.dart';

class ChecklistController extends GetxController {
  final ChecklistRepository _repo = ChecklistRepository();

  final modelos = <ChecklistModelo>[].obs;
  final aCarregar = false.obs;
  final erro = RxnString();

  /// Mensagem do último erro de submissão (para mostrar a razão real ao user).
  final erroSubmissao = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    aCarregar.value = true;
    erro.value = null;
    try {
      modelos.value = await _repo.disponiveis();
    } catch (e) {
      erro.value = 'Não foi possível carregar as checklists.';
    } finally {
      aCarregar.value = false;
    }
  }

  Future<bool> submeter({
    required int modeloId,
    required List<Map<String, dynamic>> respostas,
    String? observacoes,
  }) async {
    erroSubmissao.value = null;
    try {
      return await _repo.submeter(modeloId: modeloId, respostas: respostas, observacoes: observacoes);
    } on DioException catch (e) {
      erroSubmissao.value = _extrairErro(e);
      return false;
    } catch (_) {
      erroSubmissao.value = 'Não foi possível submeter. Tente novamente.';
      return false;
    }
  }

  /// Extrai a mensagem útil de um erro do backend (message / primeiro erro de validação).
  String _extrairErro(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty && errors.values.first is List) {
          return (errors.values.first as List).first.toString();
        }
      }
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sem ligação à internet.';
    }
    return 'Não foi possível submeter. Tente novamente.';
  }
}
