import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/fraccao_autorizado.dart';

/// Repository de pessoas autorizadas a levantar encomendas.
/// Endpoints:
///   GET    /api/fraccao/autorizados
///   POST   /api/fraccao/autorizados
///   DELETE /api/fraccao/autorizados/{id}
class AutorizadoRepository {
  final Dio _dio;

  AutorizadoRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  Future<List<FraccaoAutorizado>> listar() async {
    final response = await _dio.get('/fraccao/autorizados');
    final items = (response.data['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(FraccaoAutorizado.fromJson)
        .toList();
    return items;
  }

  Future<FraccaoAutorizado> criar({
    required String nomeCompleto,
    required String relacao,
    String? biPassport,
    String? telefone,
  }) async {
    final response = await _dio.post(
      '/fraccao/autorizados',
      data: {
        'nome_completo': nomeCompleto,
        'relacao': relacao,
        if (biPassport != null && biPassport.isNotEmpty)
          'bi_passport': biPassport,
        if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return FraccaoAutorizado.fromJson(data);
  }

  Future<void> apagar(int id) async {
    await _dio.delete('/fraccao/autorizados/$id');
  }
}
