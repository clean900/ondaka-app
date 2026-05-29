import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../sos/models/tipo_sos.dart';

/// Repository do SOS dedicado ao guarda — endpoints /api/guarda/sos/*.
class SosGuardaRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/guarda/sos/alertas
  Future<List<AlertaListado>> meusAlertas() async {
    final r = await _dio.get('/guarda/sos/alertas');
    final raw = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return raw.map(AlertaListado.fromJson).toList();
  }

  /// GET /api/guarda/sos/alertas/{id}
  Future<AlertaDetalhado> obterDetalhe(int id) async {
    final r = await _dio.get('/guarda/sos/alertas/$id');
    return AlertaDetalhado.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/guarda/sos/alertas/{id}/estado
  /// acao: atender, resolver, falso_alarme
  Future<void> atualizarEstado(int id, String acao, {String? notas}) async {
    await _dio.patch(
      '/guarda/sos/alertas/$id/estado',
      data: {'acao': acao, if (notas != null && notas.isNotEmpty) 'notas': notas},
    );
  }
}
