import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/aviso.dart';

class AvisosPage {
  final List<Aviso> avisos;
  final int currentPage;
  final int lastPage;
  final int total;

  AvisosPage({
    required this.avisos,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class AvisoRepository {
  final Dio _dio;

  AvisoRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista avisos publicados visíveis ao user (segmentação aplicada).
  Future<AvisosPage> listar({int page = 1, int? condominioId}) async {
    final response = await _dio.get(
      '/avisos',
      queryParameters: {
        'page': page,
        if (condominioId != null) 'condominio_id': condominioId,
      },
    );

    final dataList = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>?;
    final lastPage = meta?['last_page'] as int? ??
        response.data['last_page'] as int? ??
        1;
    final currentPage = meta?['current_page'] as int? ??
        response.data['current_page'] as int? ??
        1;
    final total =
        meta?['total'] as int? ?? response.data['total'] as int? ?? 0;

    return AvisosPage(
      avisos: dataList
          .map((j) => Aviso.fromJson(j as Map<String, dynamic>))
          .toList(),
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  /// Detalhe de um aviso (marca como lido automaticamente no backend).
  Future<Aviso> obter(int id) async {
    final response = await _dio.get('/avisos/$id');
    return Aviso.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Marca aviso como lido. Se confirmar=true, regista também a confirmação.
  Future<void> marcarLido(int avisoId, {bool confirmar = false}) async {
    await _dio.post(
      '/avisos/$avisoId/marcar-lido',
      data: {'confirmar': confirmar},
    );
  }

  /// Adiciona um comentário ou resposta.
  Future<AvisoComentario> comentar(
    int avisoId,
    String mensagem, {
    int? parentId,
  }) async {
    final response = await _dio.post(
      '/avisos/$avisoId/comentarios',
      data: {
        'mensagem': mensagem,
        if (parentId != null) 'parent_id': parentId,
      },
    );
    return AvisoComentario.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
