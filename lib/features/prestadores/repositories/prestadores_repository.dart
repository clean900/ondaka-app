import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/prestador.dart';

/// Acede aos endpoints dos prestadores na API ONDAKA.
class PrestadoresRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Lista prestadores para o condómino (com proximidade opcional).
  /// GET /prestadores?lat=&lng=&categoria_id=
  Future<({bool addonActivo, List<PrestadorCategoria> categorias, List<Prestador> prestadores})>
      listar({double? lat, double? lng, int? categoriaId}) async {
    final query = <String, dynamic>{};
    if (lat != null) query['lat'] = lat;
    if (lng != null) query['lng'] = lng;
    if (categoriaId != null) query['categoria_id'] = categoriaId;

    final res = await _api.dio.get('/prestadores', queryParameters: query);
    final data = res.data as Map<String, dynamic>;

    final addonActivo = data['addon_activo'] == true;

    final categorias = (data['categorias'] as List? ?? [])
        .map((e) => PrestadorCategoria.fromJson(e as Map<String, dynamic>))
        .toList();

    final prestadores = (data['prestadores'] as List? ?? [])
        .map((e) => Prestador.fromJson(e as Map<String, dynamic>))
        .toList();

    return (addonActivo: addonActivo, categorias: categorias, prestadores: prestadores);
  }

  /// Detalhe de um prestador + avaliações.
  /// GET /prestadores/{id}
  Future<({Prestador prestador, List<AvaliacaoPrestador> avaliacoes})>
      detalhe(int prestadorId) async {
    final res = await _api.dio.get('/prestadores/$prestadorId');
    final data = res.data as Map<String, dynamic>;

    final prestador =
        Prestador.fromJson(data['prestador'] as Map<String, dynamic>);

    final avaliacoes = (data['avaliacoes'] as List? ?? [])
        .map((e) => AvaliacaoPrestador.fromJson(e as Map<String, dynamic>))
        .toList();

    return (prestador: prestador, avaliacoes: avaliacoes);
  }

  /// Avalia um prestador.
  /// POST /prestadores/{id}/avaliar
  Future<double> avaliar({
    required int prestadorId,
    required int estrelas,
    String? comentario,
  }) async {
    final res = await _api.dio.post(
      '/prestadores/$prestadorId/avaliar',
      data: {
        'estrelas': estrelas,
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return double.tryParse(data['media_estrelas']?.toString() ?? '0') ?? 0;
  }
}
