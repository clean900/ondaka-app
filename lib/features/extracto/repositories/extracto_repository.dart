import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/extracto_saldo.dart';
import '../models/mes_grafico.dart';
import '../models/movimento.dart';

/// Repository para o extracto financeiro do condómino.
///
/// Endpoints `/api/extracto/*` — leitura.
class ExtractoRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/extracto/saldo
  Future<ExtractoSaldo> obterSaldo() async {
    final r = await _dio.get('/extracto/saldo');
    return ExtractoSaldo.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/extracto
  Future<List<Movimento>> listarMovimentos({
    int limit = 50,
    String? desde,
    String? ate,
  }) async {
    final r = await _dio.get(
      '/extracto',
      queryParameters: {
        'limit': limit,
        if (desde != null) 'desde': desde,
        if (ate != null) 'ate': ate,
      },
    );
    final lista = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return lista.map(Movimento.fromJson).toList();
  }

  /// GET /api/extracto/grafico-mensal
  /// Devolve 12 entradas mensais (mais antigo → mais recente).
  Future<List<MesGrafico>> obterGraficoMensal() async {
    final r = await _dio.get('/extracto/grafico-mensal');
    final lista = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return lista.map(MesGrafico.fromJson).toList();
  }
}
