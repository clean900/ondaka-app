import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/tipo_sos.dart';

/// Repository do SOS — endpoints /api/sos/*.
class SosRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/sos/tipos — lista dos 13 tipos.
  Future<List<TipoSos>> obterTipos() async {
    final r = await _dio.get('/sos/tipos');
    final raw = (r.data['data'] as Map<String, dynamic>);
    return raw.entries
        .map((e) => TipoSos.fromJson(e.key, e.value as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/sos/alertas — acciona alerta com fotos opcionais (multipart).
  Future<AlertaCriado> criarAlerta({
    required String tipo,
    String? descricao,
    String? localizacao,
    List<File> fotos = const [],
  }) async {
    final formData = FormData.fromMap({
      'tipo': tipo,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      if (localizacao != null && localizacao.isNotEmpty) 'localizacao': localizacao,
    });

    for (int i = 0; i < fotos.length && i < 3; i++) {
      final f = fotos[i];
      formData.files.add(MapEntry(
        'fotos[]',
        await MultipartFile.fromFile(f.path, filename: 'sos_${DateTime.now().millisecondsSinceEpoch}_$i.jpg'),
      ));
    }

    final r = await _dio.post(
      '/sos/alertas',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return AlertaCriado.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/sos/alertas — lista dos meus alertas.
  Future<List<AlertaListado>> meusAlertas() async {
    final r = await _dio.get('/sos/alertas');
    final raw = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return raw.map(AlertaListado.fromJson).toList();
  }

  /// GET /api/sos/alertas/{id} — detalhe completo.
  Future<AlertaDetalhado> obterDetalhe(int id) async {
    final r = await _dio.get('/sos/alertas/$id');
    return AlertaDetalhado.fromJson(r.data['data'] as Map<String, dynamic>);
  }
}
