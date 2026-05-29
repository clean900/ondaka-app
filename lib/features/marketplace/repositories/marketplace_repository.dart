import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/anuncio.dart';

/// Acede aos endpoints do marketplace dos condóminos na API ONDAKA.
class MarketplaceRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Lista anúncios visíveis + flag pode_publicar + categorias.
  /// GET /marketplace?categoria_id=&tipo=&q=
  Future<({
    bool podePublicar,
    List<MarketplaceCategoria> categorias,
    List<Anuncio> anuncios,
    int pagina,
    int ultimaPagina,
  })> listar({int? categoriaId, String? tipo, String? procura, int pagina = 1}) async {
    final query = <String, dynamic>{'page': pagina};
    if (categoriaId != null) query['categoria_id'] = categoriaId;
    if (tipo != null) query['tipo'] = tipo;
    if (procura != null && procura.isNotEmpty) query['q'] = procura;

    final res = await _api.dio.get('/marketplace', queryParameters: query);
    final data = res.data as Map<String, dynamic>;

    return (
      podePublicar: data['pode_publicar'] == true,
      categorias: (data['categorias'] as List? ?? [])
          .map((e) => MarketplaceCategoria.fromJson(e as Map<String, dynamic>))
          .toList(),
      anuncios: (data['anuncios'] as List? ?? [])
          .map((e) => Anuncio.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagina: (data['pagina'] as num?)?.toInt() ?? 1,
      ultimaPagina: (data['ultima_pagina'] as num?)?.toInt() ?? 1,
    );
  }

  /// Detalhe de um anúncio.
  /// GET /marketplace/{id}
  Future<Anuncio> detalhe(int anuncioId) async {
    final res = await _api.dio.get('/marketplace/$anuncioId');
    final data = res.data as Map<String, dynamic>;
    return Anuncio.fromJson(data['anuncio'] as Map<String, dynamic>);
  }

  /// Os meus anúncios.
  /// GET /marketplace/meus
  Future<List<Anuncio>> meus() async {
    final res = await _api.dio.get('/marketplace/meus');
    final data = res.data as Map<String, dynamic>;
    return (data['anuncios'] as List? ?? [])
        .map((e) => Anuncio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Criar anúncio. Devolve (sucesso, anuncio?, erro?).
  /// POST /marketplace
  Future<({bool sucesso, Anuncio? anuncio, String? erro, bool subscricaoNecessaria})> criar(
    Map<String, dynamic> dados,
  ) async {
    try {
      final res = await _api.dio.post('/marketplace', data: dados);
      final data = res.data as Map<String, dynamic>;
      return (
        sucesso: true,
        anuncio: Anuncio.fromJson(data['anuncio'] as Map<String, dynamic>),
        erro: null,
        subscricaoNecessaria: false,
      );
    } on dio.DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data is Map
          ? (e.response?.data['mensagem']?.toString())
          : null;
      return (
        sucesso: false,
        anuncio: null,
        erro: msg ?? 'Não foi possível publicar o anúncio.',
        subscricaoNecessaria: code == 403,
      );
    } catch (e) {
      return (
        sucesso: false,
        anuncio: null,
        erro: 'Não foi possível publicar o anúncio.',
        subscricaoNecessaria: false,
      );
    }
  }

  /// Alterar estado de venda.
  /// PATCH /marketplace/{id}/estado
  Future<bool> alterarEstado(int anuncioId, String estadoVenda) async {
    final res = await _api.dio.patch('/marketplace/$anuncioId/estado', data: {
      'estado_venda': estadoVenda,
    });
    return (res.data as Map<String, dynamic>)['sucesso'] == true;
  }

  /// Denunciar anúncio.
  /// POST /marketplace/{id}/denunciar
  Future<bool> denunciar(int anuncioId, String motivo, String? detalhe) async {
    final res = await _api.dio.post('/marketplace/$anuncioId/denunciar', data: {
      'motivo': motivo,
      if (detalhe != null && detalhe.isNotEmpty) 'detalhe': detalhe,
    });
    return (res.data as Map<String, dynamic>)['sucesso'] == true;
  }

  /// Upload de fotos para um anuncio (multipart).
  /// POST /marketplace/{id}/fotos
  Future<bool> uploadFotos(int anuncioId, List<String> caminhos) async {
    final formData = dio.FormData();
    for (final caminho in caminhos) {
      formData.files.add(MapEntry(
        'fotos[]',
        await dio.MultipartFile.fromFile(caminho),
      ));
    }
    final res = await _api.dio.post('/marketplace/$anuncioId/fotos', data: formData);
    return (res.data as Map<String, dynamic>)['sucesso'] == true;
  }


  /// Editar anuncio. PATCH /marketplace/{id}
  Future<bool> editar(int anuncioId, Map<String, dynamic> dados) async {
    final res = await _api.dio.patch('/marketplace/$anuncioId', data: dados);
    return (res.data as Map<String, dynamic>)['sucesso'] == true;
  }

  /// Apagar foto. DELETE /marketplace/{id}/fotos/{fotoId}
  Future<bool> apagarFoto(int anuncioId, int fotoId) async {
    final res = await _api.dio.delete('/marketplace/$anuncioId/fotos/$fotoId');
    return (res.data as Map<String, dynamic>)['sucesso'] == true;
  }


  /// Pedir subscricao do marketplace. Devolve a referencia ProxyPay.
  /// POST /marketplace/subscrever
  Future<({bool sucesso, String? entidade, int? referencia, double? montante, String? erro})> subscrever() async {
    try {
      final res = await _api.dio.post('/marketplace/subscrever');
      final data = res.data as Map<String, dynamic>;
      final ref = data['referencia'] as Map<String, dynamic>?;
      return (
        sucesso: data['sucesso'] == true,
        entidade: ref?['entidade']?.toString(),
        referencia: (ref?['referencia'] as num?)?.toInt(),
        montante: (ref?['montante'] as num?)?.toDouble(),
        erro: null,
      );
    } on dio.DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['mensagem']?.toString() : null;
      return (sucesso: false, entidade: null, referencia: null, montante: null, erro: msg ?? 'Nao foi possivel gerar a referencia.');
    }
  }

}
