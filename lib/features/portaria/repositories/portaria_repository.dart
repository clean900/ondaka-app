import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../shared/models/historico_visitas_page.dart';
import '../../../shared/models/visita.dart';
import '../../../shared/models/visita_item.dart';

/// Lançada quando o add-on Controlo de Bens não está activo (HTTP 402).
class AddonInativoException implements Exception {
  final String mensagem;
  AddonInativoException(this.mensagem);
}

/// Repository responsável pelas chamadas HTTP relacionadas com operações
/// de portaria (lado do guarda).
class PortariaRepository {
  final Dio _dio;

  PortariaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Valida um código OTP introduzido pelo guarda.
  Future<({Visita visita, Map<String, dynamic>? listaNegra})> validarOtp(String otpCode) async {
    final response = await _dio.post(
      '/portaria/validar-otp',
      data: {'otp_code': otpCode},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return (visita: Visita.fromJson(data), listaNegra: _alertaListaNegra(response));
  }

  /// Valida um QR token (scaneado pelo guarda).
  Future<({Visita visita, Map<String, dynamic>? listaNegra})> validarQr(String qrToken) async {
    final response = await _dio.post(
      '/portaria/validar-qr',
      data: {'qr_token': qrToken},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return (visita: Visita.fromJson(data), listaNegra: _alertaListaNegra(response));
  }

  /// Pré-verificação na Lista Negra (BI/matrícula/nome) antes de autorizar.
  Future<Map<String, dynamic>?> verificarListaNegra({String? bi, String? matricula, String? nome}) async {
    final response = await _dio.post('/portaria/lista-negra/verificar', data: {
      if (bi != null) 'bi': bi,
      if (matricula != null) 'matricula': matricula,
      if (nome != null) 'nome': nome,
    });
    final ln = response.data['lista_negra'];
    return ln is Map ? Map<String, dynamic>.from(ln) : null;
  }

  Map<String, dynamic>? _alertaListaNegra(Response response) {
    final ln = response.data is Map ? response.data['lista_negra'] : null;
    return ln is Map ? Map<String, dynamic>.from(ln) : null;
  }

  /// Lista visitantes que estão dentro do condomínio agora.
  Future<List<Visita>> dentroAgora({int? fraccaoId}) async {
    final response = await _dio.get(
      '/portaria/dentro-agora',
      queryParameters: {
        if (fraccaoId != null) 'fraccao_id': fraccaoId,
      },
    );

    final items = (response.data['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Visita.fromJson)
        .toList();

    return items;
  }

  /// Marca saída de uma visita em curso.
  Future<Visita> registarSaida(int visitaId, {String? observacoes}) async {
    final response = await _dio.post(
      '/portaria/visitas/$visitaId/saida',
      data: {
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Visita.fromJson(data);
  }

  /// Histórico de visitas do condomínio (todas, lado do guarda).
  ///
  /// Filtros opcionais: data desde/até, nome, fração, método de validação.
  /// Retorna paginação completa.
  Future<HistoricoVisitasPage> historicoVisitas({
    DateTime? desde,
    DateTime? ate,
    String? nome,
    MetodoValidacao? metodo,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/portaria/visitas',
      queryParameters: {
        if (desde != null) 'desde': _formatDate(desde),
        if (ate != null) 'ate': _formatDate(ate),
        if (nome != null && nome.trim().length >= 2) 'nome': nome.trim(),
        if (metodo != null) 'metodo': metodo.name,
        'page': page,
        'per_page': perPage,
      },
    );

    final dataList = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>;

    return HistoricoVisitasPage(
      visitas: dataList
          .map((json) => Visita.fromJson(json as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int,
      perPage: meta['per_page'] as int,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Add-ons da portaria activos para a empresa (controlo_bens, registo_viaturas,
  /// foto_conferencia, livro_ocorrencias, dashboard_portaria).
  Future<Map<String, bool>> features() async {
    final r = await _dio.get('/portaria/features');
    final data = (r.data['data'] as Map).cast<String, dynamic>();
    return data.map((k, v) => MapEntry(k, v == true));
  }

  /// Regista/atualiza a matrícula do veículo de uma visita (add-on registo_viaturas).
  Future<Visita> registarMatricula(int visitaId, String matricula) async {
    final r = await _dio.post(
      '/portaria/visitas/$visitaId/matricula',
      data: {'matricula': matricula},
    );
    return Visita.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  // ===========================================================================
  // Add-on Controlo de Bens — itens da visita
  // ===========================================================================

  /// Lista os itens registados numa visita.
  /// Lança [AddonInativoException] se o add-on não estiver activo (402).
  Future<List<VisitaItem>> listarItens(int visitaId) async {
    try {
      final response = await _dio.get('/portaria/visitas/$visitaId/itens');
      return (response.data['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(VisitaItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapearAddon(e);
    }
  }

  /// Regista um item à entrada da visita.
  Future<VisitaItem> registarItem(
    int visitaId, {
    required String descricao,
    int quantidade = 1,
    String? categoria,
    String? identificador,
    String? observacoes,
  }) async {
    try {
      final response = await _dio.post(
        '/portaria/visitas/$visitaId/itens',
        data: {
          'descricao': descricao,
          'quantidade': quantidade,
          if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
          if (identificador != null && identificador.isNotEmpty) 'identificador': identificador,
          if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
        },
      );
      return VisitaItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapearAddon(e);
    }
  }

  /// Regista um item NÃO declarado à entrada, detectado na saída (anomalia).
  /// Envia uma foto obrigatória (multipart) e fica a aguardar autorização.
  Future<VisitaItem> registarItemNaoDeclarado(
    int visitaId, {
    required String descricao,
    required File foto,
    int quantidade = 1,
    String? identificador,
    String? observacoes,
  }) async {
    try {
      final form = FormData.fromMap({
        'descricao': descricao,
        'quantidade': quantidade,
        if (identificador != null && identificador.isNotEmpty) 'identificador': identificador,
        if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
        'foto': await MultipartFile.fromFile(
          foto.path,
          filename: 'bem_${visitaId}_${foto.path.split('/').last}',
        ),
      });
      final response = await _dio.post(
        '/portaria/visitas/$visitaId/itens/nao-declarado',
        data: form,
      );
      return VisitaItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapearAddon(e);
    }
  }

  /// Guarda retém um bem à espera de autorização (sem resposta/recusa) → o
  /// visitante sai sem o bem e a saída desbloqueia.
  Future<VisitaItem> reterItem(int visitaId, int itemId) async {
    try {
      final response = await _dio.post('/portaria/visitas/$visitaId/itens/$itemId/reter');
      return VisitaItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapearAddon(e);
    }
  }

  /// Reconcilia um item na saída: resolucao = 'saiu' ou 'ficou'.
  Future<VisitaItem> resolverItem(
    int visitaId,
    int itemId, {
    required String resolucao,
    String? observacoes,
  }) async {
    try {
      final response = await _dio.post(
        '/portaria/visitas/$visitaId/itens/$itemId/saida',
        data: {
          'resolucao': resolucao,
          if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
        },
      );
      return VisitaItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapearAddon(e);
    }
  }

  /// Remove um item registado por engano (só enquanto estiver 'dentro').
  Future<void> removerItem(int visitaId, int itemId) async {
    try {
      await _dio.delete('/portaria/visitas/$visitaId/itens/$itemId');
    } on DioException catch (e) {
      throw _mapearAddon(e);
    }
  }

  Exception _mapearAddon(DioException e) {
    if (e.response?.statusCode == 402) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ??
              'Add-on Controlo de Bens não activo.')
          : 'Add-on Controlo de Bens não activo.';
      return AddonInativoException(msg);
    }
    return e;
  }
}
