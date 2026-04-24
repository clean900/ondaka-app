import 'fraccao.dart';
import 'visitante.dart';

/// Método pelo qual o guarda validou a entrada.
enum MetodoValidacao {
  qr,
  otp,
  manual;

  static MetodoValidacao fromString(String value) {
    return MetodoValidacao.values.firstWhere(
      (m) => m.name == value,
      orElse: () => MetodoValidacao.qr,
    );
  }

  String get label {
    return switch (this) {
      MetodoValidacao.qr => 'QR Code',
      MetodoValidacao.otp => 'Código OTP',
      MetodoValidacao.manual => 'Entrada manual',
    };
  }
}

/// Representa uma Visita efectiva — visitante entrou pelo portão.
///
/// Espelha a tabela `visitas` do backend Laravel.
/// Se `saiuEm` for null, o visitante ainda está dentro.
class Visita {
  final int id;
  final int empresaGestoraId;
  final int? preAprovacaoId;
  final int visitanteId;
  final int fraccaoId;
  final int guardaEntradaId;
  final int? guardaSaidaId;
  final DateTime entrouEm;
  final DateTime? saiuEm;
  final MetodoValidacao metodoValidacao;
  final String? observacoes;

  // Relações opcionais (quando backend as carregou via with())
  final Visitante? visitante;
  final Fraccao? fraccao;

  Visita({
    required this.id,
    required this.empresaGestoraId,
    this.preAprovacaoId,
    required this.visitanteId,
    required this.fraccaoId,
    required this.guardaEntradaId,
    this.guardaSaidaId,
    required this.entrouEm,
    this.saiuEm,
    required this.metodoValidacao,
    this.observacoes,
    this.visitante,
    this.fraccao,
  });

  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id'] as int,
      empresaGestoraId: json['empresa_gestora_id'] as int,
      preAprovacaoId: json['pre_aprovacao_id'] as int?,
      visitanteId: json['visitante_id'] as int,
      fraccaoId: json['fraccao_id'] as int,
      guardaEntradaId: json['guarda_entrada_id'] as int,
      guardaSaidaId: json['guarda_saida_id'] as int?,
      entrouEm: DateTime.parse(json['entrou_em'] as String).toLocal(),
      saiuEm: json['saiu_em'] != null
          ? DateTime.parse(json['saiu_em'] as String).toLocal()
          : null,
      metodoValidacao: MetodoValidacao.fromString(json['metodo_validacao'] as String),
      observacoes: json['observacoes'] as String?,
      visitante: json['visitante'] != null
          ? Visitante.fromJson(json['visitante'] as Map<String, dynamic>)
          : null,
      fraccao: json['fraccao'] != null
          ? Fraccao.fromJson(json['fraccao'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Se ainda está dentro do condomínio.
  bool get aindaDentro => saiuEm == null;

  /// Duração em minutos (ou null se ainda dentro).
  int? get duracaoMinutos {
    if (saiuEm == null) return null;
    return saiuEm!.difference(entrouEm).inMinutes;
  }
}
