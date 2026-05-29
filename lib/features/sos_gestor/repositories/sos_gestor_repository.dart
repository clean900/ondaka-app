import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../sos/models/tipo_sos.dart';

/// Repository do SOS dedicado ao gestor — endpoints /api/gestor/sos/*.
class SosGestorRepository {
  Dio get _dio => ApiService.to.dio;

  Future<List<AlertaListado>> meusAlertas() async {
    final r = await _dio.get('/gestor/sos/alertas');
    final raw = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return raw.map(AlertaListado.fromJson).toList();
  }

  Future<AlertaDetalhado> obterDetalhe(int id) async {
    final r = await _dio.get('/gestor/sos/alertas/$id');
    return AlertaDetalhado.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  Future<void> atualizarEstado(int id, String acao, {String? notas}) async {
    await _dio.patch(
      '/gestor/sos/alertas/$id/estado',
      data: {'acao': acao, if (notas != null && notas.isNotEmpty) 'notas': notas},
    );
  }
}
