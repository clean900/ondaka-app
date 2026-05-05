import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/encomenda.dart';

/// Repository de encomendas para o perfil condómino.
/// Endpoints disponíveis no backend (validados E2E):
///   GET    /api/encomendas
///   POST   /api/encomendas/pre-anuncio
///   POST   /api/encomendas/{id}/cancelar
class EncomendaRepository {
  final Dio _dio;

  EncomendaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista as encomendas do condómino autenticado.
  /// [estado] pode ser: aguarda_chegada, aguarda_levantamento, entregue,
  ///                    multa_aplicada, cancelada
  Future<List<Encomenda>> listar({String? estado}) async {
    final response = await _dio.get(
      '/encomendas',
      queryParameters: {
        if (estado != null && estado.isNotEmpty) 'estado': estado,
      },
    );

    final items = (response.data['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Encomenda.fromJson)
        .toList();

    return items;
  }

  /// Cria pré-anúncio de encomenda (Fluxo B).
  Future<Encomenda> preAnunciar({
    required String descricao,
    String? remetente,
    DateTime? janelaInicio,
    DateTime? janelaFim,
  }) async {
    final response = await _dio.post(
      '/encomendas/pre-anuncio',
      data: {
        'descricao': descricao,
        if (remetente != null && remetente.isNotEmpty) 'remetente': remetente,
        if (janelaInicio != null)
          'janela_inicio': _formatDate(janelaInicio),
        if (janelaFim != null) 'janela_fim': _formatDate(janelaFim),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Encomenda.fromJson(data);
  }

  /// Cancela pré-anúncio (só funciona se estado = aguarda_chegada).
  Future<Encomenda> cancelar(int id) async {
    final response = await _dio.post('/encomendas/$id/cancelar');
    final data = response.data['data'] as Map<String, dynamic>;
    return Encomenda.fromJson(data);
  }

  String _formatDate(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$mi:00';
  }
}
