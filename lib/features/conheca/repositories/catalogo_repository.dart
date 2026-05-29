import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/catalogo_feature.dart';

/// Repository público do catálogo (sem autenticação).
class CatalogoRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/catalogo
  /// Devolve a lista de categorias com features.
  Future<List<CatalogoCategoria>> obterCatalogo() async {
    final r = await _dio.get('/catalogo');
    final raw = r.data['data'] as Map<String, dynamic>;
    final cats = (raw['categorias'] as List).cast<Map<String, dynamic>>();
    return cats.map(CatalogoCategoria.fromJson).toList();
  }
}
