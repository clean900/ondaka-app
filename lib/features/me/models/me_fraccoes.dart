import 'package:flutter/foundation.dart';

/// Condominio onde o user tem fraccoes activas (dropdown).
@immutable
class MeuCondominio {
  final int id;
  final String nome;

  const MeuCondominio({required this.id, required this.nome});

  factory MeuCondominio.fromJson(Map<String, dynamic> json) {
    return MeuCondominio(
      id: json['id'] as int,
      nome: json['nome'] as String,
    );
  }
}

/// Fraccao do user (com condominio + edificio).
@immutable
class MinhaFraccao {
  final int id;
  final String identificador;
  final String? piso;
  final int? edificioId;
  final String? edificioNome;
  final int condominioId;
  final String condominioNome;

  const MinhaFraccao({
    required this.id,
    required this.identificador,
    this.piso,
    this.edificioId,
    this.edificioNome,
    required this.condominioId,
    required this.condominioNome,
  });

  /// Label visivel no dropdown: "2B - Vivendas da Fase 1"
  String get labelCompleto {
    if (edificioNome != null && edificioNome!.isNotEmpty) {
      return '$identificador - $edificioNome';
    }
    return identificador;
  }

  factory MinhaFraccao.fromJson(Map<String, dynamic> json) {
    return MinhaFraccao(
      id: json['id'] as int,
      identificador: json['identificador'] as String,
      piso: json['piso']?.toString(),
      edificioId: json['edificio_id'] as int?,
      edificioNome: json['edificio_nome'] as String?,
      condominioId: json['condominio_id'] as int,
      condominioNome: json['condominio_nome'] as String,
    );
  }
}

/// Payload completo do GET /me/fraccoes.
@immutable
class MeFraccoesPayload {
  final List<MeuCondominio> condominios;
  final List<MinhaFraccao> fraccoes;

  const MeFraccoesPayload({
    required this.condominios,
    required this.fraccoes,
  });

  /// Filtra fraccoes por condominio.
  List<MinhaFraccao> fraccoesDoCondominio(int condominioId) {
    return fraccoes.where((f) => f.condominioId == condominioId).toList();
  }

  factory MeFraccoesPayload.fromJson(Map<String, dynamic> json) {
    final condList = json['condominios'] as List<dynamic>? ?? [];
    final fracList = json['fraccoes'] as List<dynamic>? ?? [];
    return MeFraccoesPayload(
      condominios: condList
          .map((j) => MeuCondominio.fromJson(j as Map<String, dynamic>))
          .toList(),
      fraccoes: fracList
          .map((j) => MinhaFraccao.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}
