import 'package:flutter/material.dart';

enum AvisoCategoria {
  geral('geral', 'Geral', Icons.info_outline),
  manutencao('manutencao', 'Manutenção', Icons.build),
  reuniao('reuniao', 'Reunião', Icons.groups),
  urgente('urgente', 'Urgente', Icons.priority_high),
  evento('evento', 'Evento', Icons.event),
  avisoLegal('aviso_legal', 'Aviso Legal', Icons.gavel),
  outro('outro', 'Outro', Icons.help_outline);

  final String slug;
  final String label;
  final IconData icon;

  const AvisoCategoria(this.slug, this.label, this.icon);

  static AvisoCategoria fromString(String value) {
    return AvisoCategoria.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => AvisoCategoria.geral,
    );
  }
}

enum AvisoPrioridade {
  baixa('baixa', 'Baixa', Color(0xFF6B7280)),
  media('media', 'Média', Color(0xFF3B82F6)),
  alta('alta', 'Alta', Color(0xFFF97316)),
  urgente('urgente', 'Urgente', Color(0xFFEF4444));

  final String slug;
  final String label;
  final Color cor;

  const AvisoPrioridade(this.slug, this.label, this.cor);

  static AvisoPrioridade fromString(String value) {
    return AvisoPrioridade.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => AvisoPrioridade.media,
    );
  }
}

enum AvisoEstado {
  rascunho('rascunho', 'Rascunho'),
  agendado('agendado', 'Agendado'),
  publicado('publicado', 'Publicado'),
  arquivado('arquivado', 'Arquivado');

  final String slug;
  final String label;

  const AvisoEstado(this.slug, this.label);

  static AvisoEstado fromString(String value) {
    return AvisoEstado.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => AvisoEstado.rascunho,
    );
  }
}

class AvisoAnexo {
  final int id;
  final int avisoId;
  final String path;
  final String nomeOriginal;
  final String mimeType;
  final int tamanhoBytes;

  AvisoAnexo({
    required this.id,
    required this.avisoId,
    required this.path,
    required this.nomeOriginal,
    required this.mimeType,
    required this.tamanhoBytes,
  });

  bool get eImagem => mimeType.startsWith('image/');
  bool get ePdf => mimeType == 'application/pdf';

  factory AvisoAnexo.fromJson(Map<String, dynamic> json) {
    return AvisoAnexo(
      id: json['id'] as int,
      avisoId: json['aviso_id'] as int,
      path: json['path'] as String,
      nomeOriginal: json['nome_original'] as String,
      mimeType: json['mime_type'] as String,
      tamanhoBytes: (json['tamanho_bytes'] as num).toInt(),
    );
  }
}

class AvisoComentario {
  final int id;
  final int avisoId;
  final int userId;
  final String? userName;
  final int? parentId;
  final String mensagem;
  final bool destaque;
  final DateTime createdAt;
  final List<AvisoComentario> respostas;

  AvisoComentario({
    required this.id,
    required this.avisoId,
    required this.userId,
    this.userName,
    this.parentId,
    required this.mensagem,
    this.destaque = false,
    required this.createdAt,
    this.respostas = const [],
  });

  bool get eResposta => parentId != null;

  factory AvisoComentario.fromJson(Map<String, dynamic> json) {
    return AvisoComentario(
      id: json['id'] as int,
      avisoId: json['aviso_id'] as int,
      userId: json['user_id'] as int,
      userName: (json['user'] as Map?)?['name'] as String?,
      parentId: json['parent_id'] as int?,
      mensagem: json['mensagem'] as String,
      destaque: json['destaque'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      respostas: (json['respostas'] as List?)
              ?.map((r) => AvisoComentario.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Aviso {
  final int id;
  final int empresaGestoraId;
  final int condominioId;
  final int autorUserId;
  final String? autorNome;
  final String? condominioNome;
  final String titulo;
  final String descricao;
  final AvisoCategoria categoria;
  final AvisoPrioridade prioridade;
  final AvisoEstado estado;
  final DateTime? publicarEm;
  final DateTime? publicadoEm;
  final DateTime? arquivarEm;
  final bool permiteComentarios;
  final bool requerConfirmacao;
  final DateTime createdAt;
  final List<AvisoAnexo> anexos;
  final List<AvisoComentario> comentarios;
  final int? comentariosCount;

  // Estado pessoal do user (preenchido pelo backend quando relevante)
  final bool jaLido;
  final bool jaConfirmado;

  Aviso({
    required this.id,
    required this.empresaGestoraId,
    required this.condominioId,
    required this.autorUserId,
    this.autorNome,
    this.condominioNome,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.prioridade,
    required this.estado,
    this.publicarEm,
    this.publicadoEm,
    this.arquivarEm,
    required this.permiteComentarios,
    required this.requerConfirmacao,
    required this.createdAt,
    this.anexos = const [],
    this.comentarios = const [],
    this.comentariosCount,
    this.jaLido = false,
    this.jaConfirmado = false,
  });

  factory Aviso.fromJson(Map<String, dynamic> json) {
    return Aviso(
      id: json['id'] as int,
      empresaGestoraId: json['empresa_gestora_id'] as int,
      condominioId: json['condominio_id'] as int,
      autorUserId: json['autor_user_id'] as int,
      autorNome: (json['autor'] as Map?)?['name'] as String?,
      condominioNome: (json['condominio'] as Map?)?['nome'] as String?,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      categoria: AvisoCategoria.fromString(json['categoria'] as String),
      prioridade: AvisoPrioridade.fromString(json['prioridade'] as String),
      estado: AvisoEstado.fromString(json['estado'] as String),
      publicarEm: json['publicar_em'] != null
          ? DateTime.parse(json['publicar_em'] as String).toLocal()
          : null,
      publicadoEm: json['publicado_em'] != null
          ? DateTime.parse(json['publicado_em'] as String).toLocal()
          : null,
      arquivarEm: json['arquivar_em'] != null
          ? DateTime.parse(json['arquivar_em'] as String).toLocal()
          : null,
      permiteComentarios: json['permite_comentarios'] as bool? ?? true,
      requerConfirmacao: json['requer_confirmacao'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      anexos: (json['anexos'] as List?)
              ?.map((a) => AvisoAnexo.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      comentarios: (json['comentarios'] as List?)
              ?.map((c) => AvisoComentario.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      comentariosCount: json['comentarios_count'] as int?,
      jaLido: json['ja_lido'] as bool? ?? false,
      jaConfirmado: json['ja_confirmado'] as bool? ?? false,
    );
  }
}
