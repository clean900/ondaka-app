import 'package:flutter/material.dart';

/// Tipo de pedido: particular (privado) ou publico (visivel a todos os condominos).
enum TicketTipo {
  particular('particular', 'Particular', Icons.lock_outline),
  publico('publico', 'Publico', Icons.public);

  final String slug;
  final String label;
  final IconData icon;

  const TicketTipo(this.slug, this.label, this.icon);

  static TicketTipo fromString(String? value) {
    if (value == null) return TicketTipo.particular;
    return TicketTipo.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => TicketTipo.particular,
    );
  }
}

/// Categorias possíveis de tickets.
enum TicketCategoria {
  manutencao('manutencao', 'Manutenção', Icons.build),
  limpeza('limpeza', 'Limpeza', Icons.cleaning_services),
  seguranca('seguranca', 'Segurança', Icons.shield),
  ruido('ruido', 'Ruído', Icons.volume_up),
  agua('agua', 'Água', Icons.water_drop),
  electricidade('electricidade', 'Electricidade', Icons.bolt),
  jardim('jardim', 'Jardim', Icons.park),
  estacionamento('estacionamento', 'Estacionamento', Icons.local_parking),
  reclamacao('reclamacao', 'Reclamação', Icons.report_problem),
  sugestao('sugestao', 'Sugestão', Icons.lightbulb_outline),
  outro('outro', 'Outro', Icons.help_outline);

  final String slug;
  final String label;
  final IconData icon;

  const TicketCategoria(this.slug, this.label, this.icon);

  static TicketCategoria fromString(String value) {
    return TicketCategoria.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => TicketCategoria.outro,
    );
  }
}

/// Prioridades.
enum TicketPrioridade {
  baixa('baixa', 'Baixa', Color(0xFF6B7280)),
  media('media', 'Média', Color(0xFF3B82F6)),
  alta('alta', 'Alta', Color(0xFFF97316)),
  urgente('urgente', 'Urgente', Color(0xFFEF4444));

  final String slug;
  final String label;
  final Color cor;

  const TicketPrioridade(this.slug, this.label, this.cor);

  static TicketPrioridade fromString(String value) {
    return TicketPrioridade.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => TicketPrioridade.media,
    );
  }
}

/// Estados.
enum TicketEstado {
  aberto('aberto', 'Aberto', Color(0xFF3B82F6)),
  emAnalise('em_analise', 'Em análise', Color(0xFFF59E0B)),
  emCurso('em_curso', 'Em curso', Color(0xFF06B6D4)),
  resolvido('resolvido', 'Resolvido', Color(0xFF10B981)),
  fechado('fechado', 'Fechado', Color(0xFF6B7280)),
  cancelado('cancelado', 'Cancelado', Color(0xFFEF4444));

  final String slug;
  final String label;
  final Color cor;

  const TicketEstado(this.slug, this.label, this.cor);

  static TicketEstado fromString(String value) {
    return TicketEstado.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => TicketEstado.aberto,
    );
  }

  bool get estaAberto =>
      this != TicketEstado.resolvido &&
      this != TicketEstado.fechado &&
      this != TicketEstado.cancelado;
}

/// Foto anexa a um ticket.
class TicketFoto {
  final int id;
  final int ticketId;
  final String path;
  final String? nomeOriginal;
  final String? mimeType;
  final int tamanhoBytes;

  TicketFoto({
    required this.id,
    required this.ticketId,
    required this.path,
    this.nomeOriginal,
    this.mimeType,
    required this.tamanhoBytes,
  });

  factory TicketFoto.fromJson(Map<String, dynamic> json) {
    return TicketFoto(
      id: json['id'] as int,
      ticketId: json['ticket_id'] as int,
      path: json['path'] as String,
      nomeOriginal: json['nome_original'] as String?,
      mimeType: json['mime_type'] as String?,
      tamanhoBytes: (json['tamanho_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Comentário num ticket.
class TicketComentario {
  final int id;
  final int ticketId;
  final int userId;
  final String? userName;
  final String mensagem;
  final bool publico;
  final String? mudancaEstadoDe;
  final String? mudancaEstadoPara;
  final DateTime createdAt;

  TicketComentario({
    required this.id,
    required this.ticketId,
    required this.userId,
    this.userName,
    required this.mensagem,
    required this.publico,
    this.mudancaEstadoDe,
    this.mudancaEstadoPara,
    required this.createdAt,
  });

  bool get eMudancaEstado => mudancaEstadoPara != null;

  factory TicketComentario.fromJson(Map<String, dynamic> json) {
    return TicketComentario(
      id: json['id'] as int,
      ticketId: json['ticket_id'] as int,
      userId: json['user_id'] as int,
      userName: (json['user'] as Map?)?['name'] as String?,
      mensagem: json['mensagem'] as String,
      publico: json['publico'] as bool? ?? true,
      mudancaEstadoDe: json['mudanca_estado_de'] as String?,
      mudancaEstadoPara: json['mudanca_estado_para'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

/// Categoria dinamica vinda do backend (GET /api/tickets/categorias).
/// Cada empresa pode ter as suas proprias categorias com tipo (particular/publico).
class TicketCategoriaDinamica {
  final int id;
  final String nome;
  final String slug;
  final String? icone;
  final String tipo; // particular | publico
  final int ordem;

  TicketCategoriaDinamica({
    required this.id,
    required this.nome,
    required this.slug,
    this.icone,
    required this.tipo,
    required this.ordem,
  });

  /// Devolve o IconData Material correspondente ao slug.
  IconData get materialIcon => TicketCategoria.fromString(slug).icon;

  factory TicketCategoriaDinamica.fromJson(Map<String, dynamic> json) {
    return TicketCategoriaDinamica(
      id: json['id'] as int,
      nome: json['nome'] as String,
      slug: json['slug'] as String,
      icone: json['icone'] as String?,
      tipo: json['tipo'] as String? ?? 'particular',
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Modelo principal Ticket.
class Ticket {
  final int id;
  final int empresaGestoraId;
  final int condominioId;
  final int abertoPorUserId;
  final int? fraccaoId;
  final int? atribuidoAUserId;
  final String titulo;
  final String descricao;
  final TicketCategoria categoria;
  final TicketPrioridade prioridade;
  final TicketEstado estado;
  final TicketTipo tipo;
  final int? categoriaId;
  final String? categoriaNome;
  final int? atribuidoAEmpresaId;
  final DateTime? canceladoEm;
  final String? motivoCancelamento;
  final int totalApoios;
  final bool apoiadoPeloUser;
  final String? atribuidoAEmpresaNome;
  final DateTime? atribuidoEm;
  final DateTime? resolvidoEm;
  final DateTime? fechadoEm;
  final bool threadsPublicas;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relações opcionais
  final String? abertoPorNome;
  final String? atribuidoANome;
  final String? fraccaoIdentificador;
  final String? condominioNome;
  final List<TicketFoto> fotos;
  final List<TicketComentario> comentarios;

  Ticket({
    required this.id,
    required this.empresaGestoraId,
    required this.condominioId,
    required this.abertoPorUserId,
    this.fraccaoId,
    this.atribuidoAUserId,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.prioridade,
    required this.estado,
    required this.tipo,
    this.categoriaId,
    this.categoriaNome,
    this.atribuidoAEmpresaId,
    this.canceladoEm,
    this.motivoCancelamento,
    this.totalApoios = 0,
    this.apoiadoPeloUser = false,
    this.atribuidoAEmpresaNome,
    this.atribuidoEm,
    this.resolvidoEm,
    this.fechadoEm,
    required this.threadsPublicas,
    required this.createdAt,
    required this.updatedAt,
    this.abertoPorNome,
    this.atribuidoANome,
    this.fraccaoIdentificador,
    this.condominioNome,
    this.fotos = const [],
    this.comentarios = const [],
  });


  /// Cria uma copia com campos alterados (util para optimistic UI).
  Ticket copyWith({
    int? totalApoios,
    bool? apoiadoPeloUser,
    TicketEstado? estado,
    DateTime? canceladoEm,
    String? motivoCancelamento,
    int? atribuidoAUserId,
    String? atribuidoANome,
    int? atribuidoAEmpresaId,
    String? atribuidoAEmpresaNome,
  }) {
    return Ticket(
      id: id,
      empresaGestoraId: empresaGestoraId,
      condominioId: condominioId,
      abertoPorUserId: abertoPorUserId,
      fraccaoId: fraccaoId,
      atribuidoAUserId: atribuidoAUserId ?? this.atribuidoAUserId,
      atribuidoAEmpresaId: atribuidoAEmpresaId ?? this.atribuidoAEmpresaId,
      titulo: titulo,
      descricao: descricao,
      tipo: tipo,
      categoriaId: categoriaId,
      categoriaNome: categoriaNome,
      categoria: categoria,
      prioridade: prioridade,
      estado: estado ?? this.estado,
      atribuidoEm: atribuidoEm,
      resolvidoEm: resolvidoEm,
      fechadoEm: fechadoEm,
      canceladoEm: canceladoEm ?? this.canceladoEm,
      motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
      threadsPublicas: threadsPublicas,
      totalApoios: totalApoios ?? this.totalApoios,
      apoiadoPeloUser: apoiadoPeloUser ?? this.apoiadoPeloUser,
      createdAt: createdAt,
      updatedAt: updatedAt,
      abertoPorNome: abertoPorNome,
      atribuidoANome: atribuidoANome ?? this.atribuidoANome,
      atribuidoAEmpresaNome: atribuidoAEmpresaNome ?? this.atribuidoAEmpresaNome,
      fraccaoIdentificador: fraccaoIdentificador,
      condominioNome: condominioNome,
      fotos: fotos,
      comentarios: comentarios,
    );
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      empresaGestoraId: json['empresa_gestora_id'] as int,
      condominioId: json['condominio_id'] as int,
      abertoPorUserId: json['aberto_por_user_id'] as int,
      fraccaoId: json['fraccao_id'] as int?,
      atribuidoAUserId: json['atribuido_a_user_id'] as int?,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      categoria: TicketCategoria.fromString(json['categoria'] as String),
      prioridade: TicketPrioridade.fromString(json['prioridade'] as String),
      estado: TicketEstado.fromString(json['estado'] as String),
      tipo: TicketTipo.fromString(json['tipo'] as String?),
      categoriaId: json['categoria_id'] as int?,
      categoriaNome: (json['categoria_obj'] as Map?)?['nome'] as String?,
      atribuidoAEmpresaId: json['atribuido_a_empresa_id'] as int?,
      canceladoEm: json['cancelado_em'] != null
          ? DateTime.parse(json['cancelado_em'] as String).toLocal()
          : null,
      motivoCancelamento: json['motivo_cancelamento'] as String?,
      totalApoios: (json['total_apoios'] as num?)?.toInt() ?? 0,
      apoiadoPeloUser: json['apoiado_pelo_user'] as bool? ?? false,
      atribuidoAEmpresaNome: (json['atribuido_a_empresa'] as Map?)?['nome'] as String?,
      atribuidoEm: json['atribuido_em'] != null
          ? DateTime.parse(json['atribuido_em'] as String).toLocal()
          : null,
      resolvidoEm: json['resolvido_em'] != null
          ? DateTime.parse(json['resolvido_em'] as String).toLocal()
          : null,
      fechadoEm: json['fechado_em'] != null
          ? DateTime.parse(json['fechado_em'] as String).toLocal()
          : null,
      threadsPublicas: json['threads_publicas'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      abertoPorNome: (json['aberto_por'] as Map?)?['name'] as String?,
      atribuidoANome: (json['atribuido_a'] as Map?)?['name'] as String?,
      fraccaoIdentificador:
          (json['fraccao'] as Map?)?['identificador'] as String?,
      condominioNome: (json['condominio'] as Map?)?['nome'] as String?,
      fotos: (json['fotos'] as List?)
              ?.map((f) => TicketFoto.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      comentarios: (json['comentarios'] as List?)
              ?.map((c) =>
                  TicketComentario.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
