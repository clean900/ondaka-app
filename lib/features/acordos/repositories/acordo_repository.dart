import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/acordo.dart';

class AcordosResposta {
  final List<Acordo> acordos;
  final LimitacaoInfo? limitacao;

  AcordosResposta({required this.acordos, this.limitacao});
}

class AcordoRepository {
  final Dio _dio;

  AcordoRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  Future<AcordosResposta> listar() async {
    final response = await _dio.get('/acordos');
    final body = response.data as Map<String, dynamic>;
    final lista = (body['data'] as List<dynamic>? ?? [])
        .map((j) => Acordo.fromJson(j as Map<String, dynamic>))
        .toList();
    final lim = body['limitacao'] != null
        ? LimitacaoInfo.fromJson(body['limitacao'] as Map<String, dynamic>)
        : null;
    return AcordosResposta(acordos: lista, limitacao: lim);
  }

  Future<Acordo> propor(int numPrestacoes, {String? observacoes}) async {
    final response = await _dio.post('/acordos', data: {
      'num_prestacoes': numPrestacoes,
      if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
    });
    final body = response.data as Map<String, dynamic>;
    return Acordo.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Acordo> contrapropor(int acordoId, int numPrestacoes, {String? observacoes}) async {
    final response = await _dio.post('/acordos/$acordoId/contrapropor', data: {
      'num_prestacoes': numPrestacoes,
      if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
    });
    final body = response.data as Map<String, dynamic>;
    return Acordo.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Acordo> aceitar(int acordoId) async {
    final response = await _dio.post('/acordos/$acordoId/aceitar');
    final body = response.data as Map<String, dynamic>;
    return Acordo.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> recusar(int acordoId, {String? motivo}) async {
    await _dio.post('/acordos/$acordoId/recusar', data: {
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
    });
  }
}
