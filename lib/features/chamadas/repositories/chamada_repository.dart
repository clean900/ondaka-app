import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';

class ChamadaRepository {
  final Dio _dio;
  ChamadaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Imóveis do condomínio activo do guarda (para escolher quem ligar).
  Future<List<({int id, String identificador})>> fraccoes() async {
    final r = await _dio.get('/portaria/fraccoes');
    final lista = (r.data['data'] as List?) ?? [];
    return lista
        .map((e) => (
              id: e['id'] as int,
              identificador: (e['identificador'] ?? '').toString(),
            ))
        .toList();
  }

  /// Guarda liga ao condómino de uma fração. Devolve o URL da sala (com token).
  Future<String> ligarCondomino(int fraccaoId) async {
    final r = await _dio.post('/portaria/chamadas', data: {'fraccao_id': fraccaoId});
    return r.data['jitsi_url'] as String;
  }

  /// Condómino liga à portaria. Devolve o URL da sala (com token).
  Future<String> ligarPortaria() async {
    final r = await _dio.post('/chamadas/portaria');
    return r.data['jitsi_url'] as String;
  }
}
