import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
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
}
