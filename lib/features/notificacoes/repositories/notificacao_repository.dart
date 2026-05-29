import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/notificacao.dart';

/// Repository para o endpoint /api/notificacoes.
///
/// Endpoints consumidos:
/// - GET    /notificacoes                       → listar + nao_lidas
/// - POST   /notificacoes/{id}/marcar-lida      → marca 1 como lida
/// - POST   /notificacoes/marcar-todas-lidas    → marca todas
class NotificacaoRepository {
  final Dio _dio;

  NotificacaoRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista as últimas 20 notificações do user autenticado + contagem não lidas.
  Future<NotificacoesPayload> listar() async {
    final response = await _dio.get('/notificacoes');
    return NotificacoesPayload.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Marca 1 notificação como lida. Não devolve dados úteis (apenas {ok:true}).
  Future<void> marcarLida(String id) async {
    await _dio.post('/notificacoes/$id/marcar-lida');
  }

  /// Marca todas como lidas. Não devolve dados úteis.
  Future<void> marcarTodasLidas() async {
    await _dio.post('/notificacoes/marcar-todas-lidas');
  }
}
