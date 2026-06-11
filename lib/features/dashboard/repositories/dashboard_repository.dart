import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../acordos/models/acordo.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Carrega o dashboard do condómino (4 widgets numa só chamada).
  Future<DashboardData> obterCondomino() async {
    final response = await _dio.get('/dashboard/condomino');
    final body = response.data as Map<String, dynamic>;
    return DashboardData.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Verifica se o condómino está em modo limitado por dívida.
  /// Devolve LimitacaoInfo se limitado, ou null se não.
  Future<LimitacaoInfo?> estadoAcesso() async {
    final response = await _dio.get('/dashboard/condomino/estado-acesso');
    final body = response.data as Map<String, dynamic>;
    final limitado = body['limitado'] == true || body['limitado'] == 1;
    if (!limitado) return null;
    final motivo = body['motivo'];
    if (motivo is Map) {
      return LimitacaoInfo.fromJson(Map<String, dynamic>.from(motivo));
    }
    return null;
  }
}
