import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
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
}
