import 'dart:io';
import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/ticket.dart';

/// Página paginada de tickets.
class TicketsPage {
  final List<Ticket> tickets;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  TicketsPage({
    required this.tickets,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });
}

class TicketRepository {
  final Dio _dio;

  TicketRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista tickets (condomino vê só os seus, admin vê todos).
  Future<TicketsPage> listar({
    TicketEstado? estado,
    TicketCategoria? categoria,
    TicketPrioridade? prioridade,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/tickets',
      queryParameters: {
        if (estado != null) 'estado': estado.slug,
        if (categoria != null) 'categoria': categoria.slug,
        if (prioridade != null) 'prioridade': prioridade.slug,
        'page': page,
        'per_page': perPage,
      },
    );

    final dataList = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>;

    return TicketsPage(
      tickets: dataList
          .map((j) => Ticket.fromJson(j as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int,
      perPage: meta['per_page'] as int,
    );
  }

  /// Detalhe de um ticket (com fotos e comentários).
  Future<Ticket> obter(int id) async {
    final response = await _dio.get('/tickets/$id');
    return Ticket.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Cria um novo ticket. Suporta fotos opcionais via multipart.
  Future<Ticket> criar({
    required int condominioId,
    int? fraccaoId,
    required String titulo,
    required String descricao,
    required TicketCategoria categoria,
    TicketPrioridade prioridade = TicketPrioridade.media,
    List<File> fotos = const [],
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('condominio_id', condominioId.toString()),
      if (fraccaoId != null) MapEntry('fraccao_id', fraccaoId.toString()),
      MapEntry('titulo', titulo),
      MapEntry('descricao', descricao),
      MapEntry('categoria', categoria.slug),
      MapEntry('prioridade', prioridade.slug),
    ]);

    for (final foto in fotos) {
      formData.files.add(MapEntry(
        'fotos[]',
        await MultipartFile.fromFile(
          foto.path,
          filename: foto.path.split('/').last,
        ),
      ));
    }

    final response = await _dio.post('/tickets', data: formData);
    return Ticket.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Adiciona um comentário.
  Future<TicketComentario> comentar(
    int ticketId,
    String mensagem, {
    bool publico = true,
  }) async {
    final response = await _dio.post(
      '/tickets/$ticketId/comentarios',
      data: {
        'mensagem': mensagem,
        'publico': publico,
      },
    );
    return TicketComentario.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Cancela ticket.
  Future<Ticket> cancelar(int ticketId, {String? motivo}) async {
    final response = await _dio.post(
      '/tickets/$ticketId/cancelar',
      data: {if (motivo != null) 'motivo': motivo},
    );
    return Ticket.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
