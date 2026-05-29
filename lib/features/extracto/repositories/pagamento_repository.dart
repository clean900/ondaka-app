import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/pagamento.dart';

/// Repository para pagamentos do condómino.
class PagamentoRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/extracto/pagamentos
  Future<List<Pagamento>> listar() async {
    final r = await _dio.get('/extracto/pagamentos');
    final lista = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return lista.map(Pagamento.fromJson).toList();
  }

  /// GET /api/extracto/pagamentos/{id}
  Future<Pagamento> obter(int id) async {
    final r = await _dio.get('/extracto/pagamentos/$id');
    return Pagamento.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/extracto/pagamentos
  /// Submete novo pagamento com upload opcional de comprovativo.
  Future<Pagamento> submeter({
    required int fraccaoId,
    required String metodo,
    required double valor,
    required DateTime dataPagamento,
    int? contaBancariaId,
    List<int>? lancamentoIds,
    String? referenciaExterna,
    String? bancoOrigem,
    String? notasCondomino,
    File? comprovativo,
  }) async {
    final formData = FormData.fromMap({
      'fraccao_id': fraccaoId,
      if (contaBancariaId != null) 'conta_bancaria_id': contaBancariaId,
      'metodo': metodo,
      'valor': valor.toStringAsFixed(2),
      'data_pagamento':
          '${dataPagamento.year}-${dataPagamento.month.toString().padLeft(2, '0')}-${dataPagamento.day.toString().padLeft(2, '0')}',
      if (lancamentoIds != null && lancamentoIds.isNotEmpty)
        'lancamento_ids[]': lancamentoIds,
      if (referenciaExterna != null) 'referencia_externa': referenciaExterna,
      if (bancoOrigem != null) 'banco_origem': bancoOrigem,
      if (notasCondomino != null) 'notas_condomino': notasCondomino,
      if (comprovativo != null)
        'comprovativo': await MultipartFile.fromFile(
          comprovativo.path,
          filename: comprovativo.path.split('/').last,
        ),
    });

    final r = await _dio.post(
      '/extracto/pagamentos',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    return Pagamento.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/extracto/pagamentos/{id}
  Future<Pagamento> editar(
    int id, {
    String? metodo,
    double? valor,
    DateTime? dataPagamento,
    List<int>? lancamentoIds,
    String? referenciaExterna,
    String? bancoOrigem,
    String? notasCondomino,
    File? comprovativo,
  }) async {
    final formData = FormData.fromMap({
      if (metodo != null) 'metodo': metodo,
      if (valor != null) 'valor': valor.toStringAsFixed(2),
      if (dataPagamento != null)
        'data_pagamento':
            '${dataPagamento.year}-${dataPagamento.month.toString().padLeft(2, '0')}-${dataPagamento.day.toString().padLeft(2, '0')}',
      if (lancamentoIds != null) 'lancamento_ids[]': lancamentoIds,
      if (referenciaExterna != null) 'referencia_externa': referenciaExterna,
      if (bancoOrigem != null) 'banco_origem': bancoOrigem,
      if (notasCondomino != null) 'notas_condomino': notasCondomino,
      if (comprovativo != null)
        'comprovativo': await MultipartFile.fromFile(
          comprovativo.path,
          filename: comprovativo.path.split('/').last,
        ),
      // Laravel não aceita PATCH com multipart, usar POST + _method
      '_method': 'PATCH',
    });

    final r = await _dio.post(
      '/extracto/pagamentos/$id',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    return Pagamento.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/extracto/pagamentos/{id}/gerar-referencia
  Future<Map<String, dynamic>> gerarReferenciaMcx(int id) async {
    final r = await _dio.post('/extracto/pagamentos/$id/gerar-referencia');
    return r.data['data'] as Map<String, dynamic>;
  }

  /// DELETE /api/extracto/pagamentos/{id}
  Future<void> cancelar(int id) async {
    await _dio.delete('/extracto/pagamentos/$id');
  }

  /// Descarrega o PDF de Confirmacao de Pagamento (autenticado) para um
  /// ficheiro temporario e devolve o caminho local.
  Future<String> descarregarConfirmacao(int pagamentoId) async {
    final dir = await getTemporaryDirectory();
    final destino = '${dir.path}/confirmacao-$pagamentoId.pdf';
    await _dio.download(
      '/extracto/pagamentos/$pagamentoId/confirmacao-pdf',
      destino,
    );
    return destino;
  }

}
