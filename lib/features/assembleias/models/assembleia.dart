import 'package:flutter/material.dart';

enum AssembleiaEstado {
  agendada('agendada', 'Agendada', Color(0xFF3B82F6)),
  emCurso('em_curso', 'Em curso', Color(0xFF10B981)),
  concluida('concluida', 'Concluída', Color(0xFF6B7280)),
  cancelada('cancelada', 'Cancelada', Color(0xFFEF4444));

  final String slug;
  final String label;
  final Color cor;

  const AssembleiaEstado(this.slug, this.label, this.cor);

  static AssembleiaEstado fromString(String value) {
    return AssembleiaEstado.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => AssembleiaEstado.agendada,
    );
  }
}

class Assembleia {
  final int id;
  final String numero;
  final String tipo;
  final String titulo;
  final String? ordemDoDia;
  final DateTime dataAgendada;
  final String? local;
  final String modo;
  final AssembleiaEstado estado;
  final bool actaGerada;
  final String? actaPath;
  final String? salaJitsi;

  Assembleia({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.titulo,
    this.ordemDoDia,
    required this.dataAgendada,
    this.local,
    required this.modo,
    required this.estado,
    required this.actaGerada,
    this.actaPath,
    this.salaJitsi,
  });

  factory Assembleia.fromJson(Map<String, dynamic> json) {
    return Assembleia(
      id: json['id'] as int,
      numero: json['numero'] as String,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      ordemDoDia: json['ordem_do_dia'] as String?,
      dataAgendada: DateTime.parse(json['data_agendada'] as String).toLocal(),
      local: json['local'] as String?,
      modo: json['modo'] as String,
      estado: AssembleiaEstado.fromString(json['estado'] as String),
      actaGerada: json['acta_gerada'] == true || json['acta_gerada'] == 1,
      actaPath: json['acta_path'] as String?,
      salaJitsi: json['sala_jitsi'] as String?,
    );
  }
}

class PontoVotacao {
  final int id;
  final int ordem;
  final String titulo;
  final String? descricao;
  final String tipo;
  final String estado;
  final List<dynamic> opcoes;
  final String? meuVoto;
  final bool votacaoAberta;

  PontoVotacao({
    required this.id,
    required this.ordem,
    required this.titulo,
    this.descricao,
    required this.tipo,
    required this.estado,
    required this.opcoes,
    this.meuVoto,
    required this.votacaoAberta,
  });

  factory PontoVotacao.fromJson(Map<String, dynamic> json) {
    final opcoesRaw = json['opcoes'];
    List<dynamic> opcoesList = [];
    if (opcoesRaw is List) opcoesList = opcoesRaw;
    if (opcoesRaw is String && opcoesRaw.isNotEmpty) {
      // Pode estar como JSON string
      opcoesList = [];
    }

    return PontoVotacao(
      id: json['id'] as int,
      ordem: json['ordem'] as int? ?? 0,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String?,
      tipo: json['tipo'] as String,
      estado: json['estado'] as String,
      opcoes: opcoesList,
      meuVoto: json['meu_voto'] as String?,
      votacaoAberta: json['votacao_aberta'] == true,
    );
  }
}

class AssembleiaDetalhe {
  final Assembleia assembleia;
  final int participanteId;
  final int numeroFraccoes;
  final double permilagemTotal;
  final List<PontoVotacao> pontos;

  AssembleiaDetalhe({
    required this.assembleia,
    required this.participanteId,
    required this.numeroFraccoes,
    required this.permilagemTotal,
    required this.pontos,
  });

  factory AssembleiaDetalhe.fromJson(Map<String, dynamic> json) {
    return AssembleiaDetalhe(
      assembleia: Assembleia.fromJson(json['assembleia'] as Map<String, dynamic>),
      participanteId: json['participante']['id'] as int,
      numeroFraccoes: json['participante']['numero_fraccoes'] as int? ?? 0,
      permilagemTotal: _toDouble(json['participante']['permilagem_total']),
      pontos: (json['pontos'] as List<dynamic>)
          .map((p) => PontoVotacao.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
