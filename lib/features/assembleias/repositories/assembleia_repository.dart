import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/api_service.dart';
import '../models/assembleia.dart';

class AssembleiaRepository {
  final Dio _dio;

  AssembleiaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  Future<List<Assembleia>> listar() async {
    final response = await _dio.get('/assembleias');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((j) => Assembleia.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<AssembleiaDetalhe> obter(int id) async {
    final response = await _dio.get('/assembleias/$id');
    final data = response.data as Map<String, dynamic>;
    return AssembleiaDetalhe.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> votar({
    required int assembleiaId,
    required int pontoId,
    required String opcao,
  }) async {
    await _dio.post(
      '/assembleias/$assembleiaId/pontos/$pontoId/votar',
      data: {'opcao': opcao},
    );
  }

  /// Marca presença na sala virtual (conta para quórum e acta).
  Future<void> entrar(int assembleiaId) async {
    await _dio.post('/assembleias/$assembleiaId/entrar');
  }

  /// Descarrega a acta (PDF autenticado) para um ficheiro temporário e
  /// devolve o caminho local. A acta vive em disco privado no servidor,
  /// por isso é servida pela API com auth — não por /ficheiros/.
  Future<String> descarregarActa(int assembleiaId) async {
    final dir = await getTemporaryDirectory();
    final destino = '${dir.path}/acta-$assembleiaId.pdf';
    await _dio.download('/assembleias/$assembleiaId/acta', destino);
    return destino;
  }
}
