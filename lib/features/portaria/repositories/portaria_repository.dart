import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../shared/models/historico_visitas_page.dart';
import '../../../shared/models/visita.dart';

/// Repository responsável pelas chamadas HTTP relacionadas com operações
/// de portaria (lado do guarda).
class PortariaRepository {
  final Dio _dio;

  PortariaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Valida um código OTP introduzido pelo guarda.
  Future<Visita> validarOtp(String otpCode) async {
    final response = await _dio.post(
      '/portaria/validar-otp',
      data: {'otp_code': otpCode},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Visita.fromJson(data);
  }

  /// Valida um QR token (scaneado pelo guarda).
  Future<Visita> validarQr(String qrToken) async {
    final response = await _dio.post(
      '/portaria/validar-qr',
      data: {'qr_token': qrToken},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Visita.fromJson(data);
  }

  /// Lista visitantes que estão dentro do condomínio agora.
  Future<List<Visita>> dentroAgora({int? fraccaoId}) async {
    final response = await _dio.get(
      '/portaria/dentro-agora',
      queryParameters: {
        if (fraccaoId != null) 'fraccao_id': fraccaoId,
      },
    );

    final items = (response.data['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Visita.fromJson)
        .toList();

    return items;
  }

  /// Marca saída de uma visita em curso.
  Future<Visita> registarSaida(int visitaId, {String? observacoes}) async {
    final response = await _dio.post(
      '/portaria/visitas/$visitaId/saida',
      data: {
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Visita.fromJson(data);
  }

  /// Histórico de visitas do condomínio (todas, lado do guarda).
  ///
  /// Filtros opcionais: data desde/até, nome, fração, método de validação.
  /// Retorna paginação completa.
  Future<HistoricoVisitasPage> historicoVisitas({
    DateTime? desde,
    DateTime? ate,
    String? nome,
    MetodoValidacao? metodo,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/portaria/visitas',
      queryParameters: {
        if (desde != null) 'desde': _formatDate(desde),
        if (ate != null) 'ate': _formatDate(ate),
        if (nome != null && nome.trim().length >= 2) 'nome': nome.trim(),
        if (metodo != null) 'metodo': metodo.name,
        'page': page,
        'per_page': perPage,
      },
    );

    final dataList = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>;

    return HistoricoVisitasPage(
      visitas: dataList
          .map((json) => Visita.fromJson(json as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int,
      perPage: meta['per_page'] as int,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
