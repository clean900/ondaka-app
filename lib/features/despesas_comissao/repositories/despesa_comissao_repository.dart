import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/despesa_pendente.dart';

/// Endpoints da comissão de moradores (aprovação de despesas).
class DespesaComissaoRepository {
  final ApiService _api = Get.find<ApiService>();

  /// GET /me/despesas-comissao
  Future<List<DespesaPendente>> listarPendentes() async {
    final res = await _api.dio.get('/me/despesas-comissao');
    final data = res.data as Map<String, dynamic>;
    return (data['despesas'] as List? ?? [])
        .map((e) => DespesaPendente.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /despesas-comissao/{id}/aprovar
  Future<void> aprovar(int id) async {
    await _api.dio.post('/despesas-comissao/$id/aprovar');
  }

  /// POST /despesas-comissao/{id}/recusar
  Future<void> recusar(int id, {String? motivo}) async {
    await _api.dio.post('/despesas-comissao/$id/recusar', data: {
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
    });
  }
}
