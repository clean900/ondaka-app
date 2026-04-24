import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/pre_aprovacao.dart';

/// Repository responsável pelas chamadas HTTP relacionadas com pré-aprovações.
///
/// Usa o [ApiService] (Dio configurado com baseUrl + Authorization header).
/// Todas as chamadas retornam domain models (não Maps/JSON).
class PreAprovacaoRepository {
  final Dio _dio;

  PreAprovacaoRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Cria nova pré-aprovação.
  ///
  /// Retorna a pré-aprovação criada (com QR token, OTP, etc).
  /// Pode lançar [DioException] em caso de erro de rede/API.
  Future<PreAprovacao> criar({
    required int fraccaoId,
    required String nomeVisitante,
    required String telefoneVisitante,
    required DateTime validaAte,
    DateTime? validaDesde,
    String? observacoes,
  }) async {
    final response = await _dio.post(
      '/pre-aprovacoes',
      data: {
        'fraccao_id': fraccaoId,
        'nome_visitante': nomeVisitante,
        'telefone_visitante': telefoneVisitante,
        'valida_ate': _formatForApi(validaAte),
        if (validaDesde != null) 'valida_desde': _formatForApi(validaDesde),
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return PreAprovacao.fromJson(data);
  }

  /// Lista pré-aprovações do condómino autenticado.
  Future<List<PreAprovacao>> listar({
    String? estado,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/pre-aprovacoes',
      queryParameters: {
        'estado': ?estado,
        'per_page': perPage,
      },
    );

    final items = (response.data['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(PreAprovacao.fromJson)
        .toList();

    return items;
  }

  /// Obtém detalhe de uma pré-aprovação.
  Future<PreAprovacao> obter(int id) async {
    final response = await _dio.get('/pre-aprovacoes/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return PreAprovacao.fromJson(data);
  }

  /// Cancela uma pré-aprovação pendente.
  Future<PreAprovacao> cancelar(int id) async {
    final response = await _dio.post('/pre-aprovacoes/$id/cancelar');
    final data = response.data['data'] as Map<String, dynamic>;
    return PreAprovacao.fromJson(data);
  }

  /// Formata DateTime para o formato esperado pela API Laravel.
  /// A API aceita `YYYY-MM-DD HH:MM:SS` em UTC ou ISO 8601.
  String _formatForApi(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}';
  }
}
