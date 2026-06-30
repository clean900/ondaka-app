import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/relatorio_financeiro.dart';

/// Repository da transparência financeira do condomínio (condómino).
class TransparenciaRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/condomino/relatorio-financeiro?meses=12
  Future<RelatorioFinanceiro> obter({int meses = 12}) async {
    final r = await _dio.get(
      '/condomino/relatorio-financeiro',
      queryParameters: {'meses': meses},
    );
    return RelatorioFinanceiro.fromJson(r.data as Map<String, dynamic>);
  }
}
