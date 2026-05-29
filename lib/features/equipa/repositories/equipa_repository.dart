import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/equipa_membro.dart';

/// Repository para o endpoint /api/condominio/equipa.
class EquipaRepository {
  final Dio _dio;

  EquipaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista todos os membros da equipa do condominio (users + empresas prestadoras).
  Future<List<EquipaMembro>> listar() async {
    final response = await _dio.get('/condominio/equipa');
    final list = response.data['equipa'] as List<dynamic>;
    return list
        .map((j) => EquipaMembro.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
