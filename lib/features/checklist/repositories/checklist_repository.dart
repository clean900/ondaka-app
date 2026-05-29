import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/checklist_modelo.dart';

/// Acede aos endpoints de Checklist na API ONDAKA.
class ChecklistRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Lista as checklists disponíveis para o utilizador.
  /// GET /checklist/disponiveis
  Future<List<ChecklistModelo>> disponiveis() async {
    final res = await _api.dio.get('/checklist/disponiveis');
    final data = res.data as Map<String, dynamic>;
    final lista = (data['modelos'] as List? ?? []);
    return lista.map((e) => ChecklistModelo.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Submete uma execução completa.
  /// POST /checklist/submeter
  Future<bool> submeter({
    required int modeloId,
    required List<Map<String, dynamic>> respostas,
    String? observacoes,
  }) async {
    final res = await _api.dio.post('/checklist/submeter', data: {
      'modelo_id': modeloId,
      'respostas': respostas,
      if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
    });
    return (res.data as Map<String, dynamic>)['ok'] == true;
  }
}
