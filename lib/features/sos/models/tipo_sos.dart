import 'package:flutter/material.dart';

/// Gravidade de um tipo de SOS.
enum GravidadeSos { critico, alto, medio, baixo }

/// Tipo de SOS (1 dos 13). Vem do endpoint /api/sos/tipos.
class TipoSos {
  final String key; // ex: 'incendio', 'medica', etc.
  final String label;
  final GravidadeSos gravidade;
  final String iconeKey; // nome do ícone (mapeamos para IconData)
  final String corHex;

  TipoSos({
    required this.key,
    required this.label,
    required this.gravidade,
    required this.iconeKey,
    required this.corHex,
  });

  factory TipoSos.fromJson(String key, Map<String, dynamic> json) {
    return TipoSos(
      key: key,
      label: json['label']?.toString() ?? key,
      gravidade: _parseGravidade(json['gravidade']?.toString() ?? 'baixo'),
      iconeKey: json['icone']?.toString() ?? 'help-circle',
      corHex: json['cor']?.toString() ?? '#10B981',
    );
  }

  static GravidadeSos _parseGravidade(String s) {
    return switch (s) {
      'critico' => GravidadeSos.critico,
      'alto' => GravidadeSos.alto,
      'medio' => GravidadeSos.medio,
      _ => GravidadeSos.baixo,
    };
  }

  Color get cor {
    final hex = corHex.replaceAll('#', '');
    return Color(int.parse('0xFF$hex'));
  }

  bool get ehCritico => gravidade == GravidadeSos.critico;

  /// Ícone Material para esta key (mapeamento iconeKey → IconData).
  IconData get icone {
    return switch (iconeKey) {
      'fire' => Icons.local_fire_department_outlined,
      'medical' => Icons.medical_services_outlined,
      'shield-alert' => Icons.shield_outlined,
      'alert-octagon' => Icons.report_problem_outlined,
      'wind' => Icons.air_outlined,
      'droplet' => Icons.water_drop_outlined,
      'zap-off' => Icons.power_off_outlined,
      'arrow-up-down' => Icons.elevator_outlined,
      'alert-triangle' => Icons.warning_amber_outlined,
      'paw-print' => Icons.pets_outlined,
      'user-x' => Icons.person_off_outlined,
      'volume-2' => Icons.volume_up_outlined,
      _ => Icons.help_outline,
    };
  }
}

/// Resposta do POST /api/sos/alertas.
class AlertaCriado {
  final int id;
  final String tipo;
  final String gravidade;
  final String estado;
  final int condominioId;
  final String message;

  AlertaCriado({
    required this.id,
    required this.tipo,
    required this.gravidade,
    required this.estado,
    required this.condominioId,
    required this.message,
  });

  factory AlertaCriado.fromJson(Map<String, dynamic> json) {
    return AlertaCriado(
      id: json['id'] as int,
      tipo: json['tipo']?.toString() ?? '',
      gravidade: json['gravidade']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      condominioId: json['condominio_id'] as int? ?? 0,
      message: json['message']?.toString() ?? 'Alerta enviado.',
    );
  }
}

/// Item da lista de alertas do user (resumido).
class AlertaListado {
  final int id;
  final String tipo;
  final String tipoLabel;
  final String gravidade;
  final String estado;
  final String? localizacao;
  final DateTime? createdAt;

  AlertaListado({
    required this.id,
    required this.tipo,
    required this.tipoLabel,
    required this.gravidade,
    required this.estado,
    this.localizacao,
    this.createdAt,
  });

  factory AlertaListado.fromJson(Map<String, dynamic> json) {
    return AlertaListado(
      id: json['id'] as int,
      tipo: json['tipo']?.toString() ?? '',
      tipoLabel: json['tipo_label']?.toString() ?? '',
      gravidade: json['gravidade']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      localizacao: json['localizacao']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

/// Detalhe completo de um alerta (com fotos e datas).
class AlertaDetalhado {
  final int id;
  final String tipo;
  final String tipoLabel;
  final String gravidade;
  final String estado;
  final String? descricao;
  final String? localizacao;
  final int condominioId;
  final DateTime? createdAt;
  final DateTime? atendidoEm;
  final DateTime? resolvidoEm;
  final String? resolucaoNotas;
  final List<FotoAlerta> fotos;

  AlertaDetalhado({
    required this.id,
    required this.tipo,
    required this.tipoLabel,
    required this.gravidade,
    required this.estado,
    this.descricao,
    this.localizacao,
    required this.condominioId,
    this.createdAt,
    this.atendidoEm,
    this.resolvidoEm,
    this.resolucaoNotas,
    required this.fotos,
  });

  factory AlertaDetalhado.fromJson(Map<String, dynamic> json) {
    final fotosRaw = (json['fotos'] as List? ?? []).cast<Map<String, dynamic>>();
    return AlertaDetalhado(
      id: json['id'] as int,
      tipo: json['tipo']?.toString() ?? '',
      tipoLabel: json['tipo_label']?.toString() ?? '',
      gravidade: json['gravidade']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      localizacao: json['localizacao']?.toString(),
      condominioId: json['condominio_id'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      atendidoEm: json['atendido_em'] != null ? DateTime.tryParse(json['atendido_em']) : null,
      resolvidoEm: json['resolvido_em'] != null ? DateTime.tryParse(json['resolvido_em']) : null,
      resolucaoNotas: json['resolucao_notas']?.toString(),
      fotos: fotosRaw.map(FotoAlerta.fromJson).toList(),
    );
  }
}

class FotoAlerta {
  final int id;
  final String url;

  FotoAlerta({required this.id, required this.url});

  factory FotoAlerta.fromJson(Map<String, dynamic> json) {
    return FotoAlerta(
      id: json['id'] as int,
      url: json['url']?.toString() ?? '',
    );
  }
}
