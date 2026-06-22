import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/passe.dart';

class PasseRepository {
  final Dio _dio;
  PasseRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  Future<List<Passe>> listar() async {
    final r = await _dio.get('/passes');
    final lista = (r.data['data'] as List?) ?? [];
    return lista.map((e) => Passe.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Solicita um passe. [documentoPath] é o caminho da foto/PDF do documento.
  Future<void> solicitar({
    required int fraccaoId,
    required String tipoAcesso,
    required String nomeVisitante,
    String? telefoneVisitante,
    required String tipoDocumento,
    String? numeroDocumento,
    required DateTime validaDesde,
    required DateTime validaAte,
    String? observacoes,
    required String documentoPath,
  }) async {
    final form = FormData.fromMap({
      'fraccao_id': fraccaoId,
      'tipo_acesso': tipoAcesso,
      'nome_visitante': nomeVisitante,
      if (telefoneVisitante != null && telefoneVisitante.isNotEmpty) 'telefone_visitante': telefoneVisitante,
      'tipo_documento': tipoDocumento,
      if (numeroDocumento != null && numeroDocumento.isNotEmpty) 'numero_documento': numeroDocumento,
      'valida_desde': validaDesde.toIso8601String(),
      'valida_ate': validaAte.toIso8601String(),
      if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
      'documento': await MultipartFile.fromFile(documentoPath),
    });
    await _dio.post('/passes', data: form);
  }

  Future<void> estender(int id, DateTime novaData) async {
    await _dio.post('/passes/$id/estender', data: {'valida_ate': novaData.toIso8601String()});
  }
}
