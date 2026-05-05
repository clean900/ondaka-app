import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../encomendas/models/encomenda.dart';

/// Repository para operações de encomendas no perfil PORTARIA.
///
/// Endpoints `/api/portaria/encomendas/*` — acções do guarda.
class PortariaEncomendaRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/portaria/condominio-activo
  /// Devolve {id, nome} ou null se não houver.
  Future<Map<String, dynamic>?> obterCondominioActivo() async {
    final r = await _dio.get('/portaria/condominio-activo');
    final data = r.data['data'];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  /// POST /api/portaria/condominio-activo
  /// Define o condomínio activo do guarda.
  Future<void> definirCondominioActivo(int condominioId) async {
    await _dio.post(
      '/portaria/condominio-activo',
      data: {'condominio_id': condominioId},
    );
  }

  /// GET /api/portaria/encomendas/aguarda-chegada
  /// Pré-anúncios à espera que o guarda confirme chegada.
  Future<List<Encomenda>> aguardaChegada() async {
    final r = await _dio.get('/portaria/encomendas/aguarda-chegada');
    final lista = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return lista.map(Encomenda.fromJson).toList();
  }

  /// GET /api/portaria/encomendas/portaria
  /// Encomendas em portaria a aguardar levantamento.
  Future<List<Encomenda>> naPortaria() async {
    final r = await _dio.get('/portaria/encomendas/portaria');
    final lista = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return lista.map(Encomenda.fromJson).toList();
  }

  /// GET /api/portaria/fraccoes
  /// Lista fracções do condomínio activo (com pesquisa opcional).
  Future<List<Map<String, dynamic>>> listarFraccoes({String? q}) async {
    final r = await _dio.get(
      '/portaria/fraccoes',
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return (r.data['data'] as List).cast<Map<String, dynamic>>();
  }

  /// POST /api/portaria/encomendas/registar
  /// Registar encomenda sem aviso prévio (Fluxo A).
  Future<Encomenda> registarManual({
    required int fraccaoId,
    required String descricao,
    String? remetente,
    String? notas,
  }) async {
    final r = await _dio.post(
      '/portaria/encomendas/registar',
      data: {
        'fraccao_id': fraccaoId,
        'descricao': descricao,
        if (remetente != null && remetente.isNotEmpty) 'remetente': remetente,
        if (notas != null && notas.isNotEmpty) 'notas_guarda': notas,
      },
    );
    return Encomenda.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/portaria/encomendas/historico
  /// Encomendas que ESTE guarda especifico entregou (ultimas 50).
  Future<List<Encomenda>> historico() async {
    final r = await _dio.get('/portaria/encomendas/historico');
    final lista = (r.data['data'] as List).cast<Map<String, dynamic>>();
    return lista.map(Encomenda.fromJson).toList();
  }

  /// POST /api/portaria/encomendas/{id}/marcar-chegada
  /// Confirma chegada de pré-anúncio (Fluxo B).
  Future<Encomenda> marcarChegada(int id, {String? notas}) async {
    final r = await _dio.post(
      '/portaria/encomendas/$id/marcar-chegada',
      data: {
        if (notas != null && notas.isNotEmpty) 'notas_guarda': notas,
      },
    );
    return Encomenda.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/portaria/encomendas/{id}/entregar
  /// Marca como entregue ao titular ou pessoa autorizada.
  Future<Encomenda> entregar(
    int id, {
    String? levantadaPor,
    int? fraccaoAutorizadoId,
  }) async {
    final r = await _dio.post(
      '/portaria/encomendas/$id/entregar',
      data: {
        if (levantadaPor != null) 'levantada_por': levantadaPor,
        if (fraccaoAutorizadoId != null)
          'fraccao_autorizado_id': fraccaoAutorizadoId,
      },
    );
    return Encomenda.fromJson(r.data['data'] as Map<String, dynamic>);
  }
}
