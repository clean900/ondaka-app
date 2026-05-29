import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/nps_pedido.dart';

/// Acede aos endpoints do NPS na API ONDAKA.
class NpsRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Consulta se deve pedir NPS e quais os pedidos pendentes.
  /// GET /nps/estado
  Future<List<NpsPedido>> pedidosPendentes() async {
    final res = await _api.dio.get('/nps/estado');
    final data = res.data as Map<String, dynamic>;
    if (data['deve_pedir'] != true) return [];
    final lista = (data['pedidos'] as List? ?? []);
    return lista.map((e) => NpsPedido.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Grava uma resposta NPS.
  /// POST /nps/responder
  Future<bool> responder({
    required String alvo,
    required int nota,
    String? comentario,
    String? seguimento,
  }) async {
    final res = await _api.dio.post('/nps/responder', data: {
      'alvo': alvo,
      'nota': nota,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      if (seguimento != null && seguimento.isNotEmpty) 'seguimento': seguimento,
    });
    return (res.data as Map<String, dynamic>)['sucesso'] == true;
  }
}
