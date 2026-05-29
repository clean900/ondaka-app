import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/me_fraccoes.dart';

/// Repository para endpoints do user autenticado (/api/me/*).
class MeRepository {
  final Dio _dio;

  MeRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista condominios + fraccoes activas do user logado.
  /// Util para popular dropdowns ao criar pedidos, visitas, etc.
  Future<MeFraccoesPayload> fraccoes() async {
    final response = await _dio.get('/me/fraccoes');
    return MeFraccoesPayload.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
