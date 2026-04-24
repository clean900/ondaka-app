import '../../../shared/models/fraccao.dart';

/// Estados possíveis de uma pré-aprovação.
enum EstadoPreAprovacao {
  pendente,
  usada,
  expirada,
  cancelada;

  /// Converte string vinda da API para enum.
  static EstadoPreAprovacao fromString(String value) {
    return EstadoPreAprovacao.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoPreAprovacao.pendente,
    );
  }

  /// Label humano em português.
  String get label {
    return switch (this) {
      EstadoPreAprovacao.pendente => 'Pendente',
      EstadoPreAprovacao.usada => 'Utilizada',
      EstadoPreAprovacao.expirada => 'Expirada',
      EstadoPreAprovacao.cancelada => 'Cancelada',
    };
  }
}

/// Representa uma pré-aprovação de visitante.
///
/// Espelha a tabela `pre_aprovacoes` do backend Laravel.
class PreAprovacao {
  final int id;
  final int empresaGestoraId;
  final int condominoId;
  final int fraccaoId;
  final String nomeVisitante;
  final String telefoneVisitante;
  final String qrToken;
  final String otpCode;
  final DateTime? validaDesde;
  final DateTime validaAte;
  final EstadoPreAprovacao estado;
  final String? observacoes;
  final bool smsEnviado;
  final DateTime? smsEnviadoEm;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relações opcionais (quando backend as carregou)
  final Fraccao? fraccao;

  PreAprovacao({
    required this.id,
    required this.empresaGestoraId,
    required this.condominoId,
    required this.fraccaoId,
    required this.nomeVisitante,
    required this.telefoneVisitante,
    required this.qrToken,
    required this.otpCode,
    this.validaDesde,
    required this.validaAte,
    required this.estado,
    this.observacoes,
    required this.smsEnviado,
    this.smsEnviadoEm,
    required this.createdAt,
    required this.updatedAt,
    this.fraccao,
  });

  factory PreAprovacao.fromJson(Map<String, dynamic> json) {
    return PreAprovacao(
      id: json['id'] as int,
      empresaGestoraId: json['empresa_gestora_id'] as int,
      condominoId: json['condomino_id'] as int,
      fraccaoId: json['fraccao_id'] as int,
      nomeVisitante: json['nome_visitante'] as String,
      telefoneVisitante: json['telefone_visitante'] as String,
      qrToken: json['qr_token'] as String,
      otpCode: json['otp_code'] as String,
      validaDesde: json['valida_desde'] != null
          ? DateTime.parse(json['valida_desde'] as String).toLocal()
          : null,
      validaAte: DateTime.parse(json['valida_ate'] as String).toLocal(),
      estado: EstadoPreAprovacao.fromString(json['estado'] as String),
      observacoes: json['observacoes'] as String?,
      smsEnviado: json['sms_enviado'] as bool? ?? false,
      smsEnviadoEm: json['sms_enviado_em'] != null
          ? DateTime.parse(json['sms_enviado_em'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      fraccao: json['fraccao'] != null
          ? Fraccao.fromJson(json['fraccao'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Se ainda pode ser usada.
  bool get estaPendente => estado == EstadoPreAprovacao.pendente;

  /// Se já expirou (data passou).
  bool get dataExpirou => DateTime.now().isAfter(validaAte);
}
