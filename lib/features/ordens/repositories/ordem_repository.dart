import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/ordem.dart';

class OrdensPage {
  final List<Ordem> ordens;
  final int currentPage;
  final int lastPage;
  final int total;

  OrdensPage({
    required this.ordens,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class OrdemRepository {
  final Dio _dio;

  OrdemRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  Future<OrdensPage> listar({String? estado, int page = 1}) async {
    final response = await _dio.get(
      '/ordens',
      queryParameters: {
        if (estado != null) 'estado': estado,
        'page': page,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final dataList = data['data'] as List<dynamic>;

    return OrdensPage(
      ordens: dataList
          .map((j) => Ordem.fromJson(j as Map<String, dynamic>))
          .toList(),
      currentPage: data['current_page'] as int? ?? 1,
      lastPage: data['last_page'] as int? ?? 1,
      total: data['total'] as int? ?? 0,
    );
  }

  Future<Ordem> obter(int id) async {
    final response = await _dio.get('/ordens/$id');
    return Ordem.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
