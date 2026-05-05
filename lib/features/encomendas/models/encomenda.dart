class Encomenda {
  final int id;
  final String descricao;
  final String? remetente;
  final String? notasGuarda;
  final String estado; // aguarda_chegada, aguarda_levantamento, entregue, multa_aplicada, cancelada
  final String origem; // pre_anunciada, sem_aviso
  final String localAtual; // portaria, administracao, entregue
  final DateTime? janelaInicio;
  final DateTime? janelaFim;
  final DateTime? chegouEm;
  final DateTime? levantadaEm;
  final String? levantadaPor;
  final DateTime? multaAplicadaEm;
  final String? multaValorKz;
  final String? multaEstado; // pendente, paga, desbloqueada
  final String? multaPagoVia; // proxypay, extracto, dinheiro
  final DateTime? multaPagoEm;
  final String? multaPagoObservacoes;
  final String? fotoPath;
  final FraccaoEncomenda? fraccao;
  final CondominoEncomenda? condomino;
  final UserBasic? recebidaPor;
  final UserBasic? entreguePor;
  final DateTime createdAt;

  Encomenda({
    required this.id,
    required this.descricao,
    this.remetente,
    this.notasGuarda,
    required this.estado,
    required this.origem,
    required this.localAtual,
    this.janelaInicio,
    this.janelaFim,
    this.chegouEm,
    this.levantadaEm,
    this.levantadaPor,
    this.multaAplicadaEm,
    this.multaValorKz,
    this.multaEstado,
    this.multaPagoVia,
    this.multaPagoEm,
    this.multaPagoObservacoes,
    this.fotoPath,
    this.fraccao,
    this.condomino,
    this.recebidaPor,
    this.entreguePor,
    required this.createdAt,
  });

  factory Encomenda.fromJson(Map<String, dynamic> json) {
    return Encomenda(
      id: json['id'] as int,
      descricao: json['descricao'] as String,
      remetente: json['remetente'] as String?,
      notasGuarda: json['notas_guarda'] as String?,
      estado: json['estado'] as String,
      origem: json['origem'] as String,
      localAtual: json['local_atual'] as String,
      janelaInicio: _parseDate(json['janela_inicio']),
      janelaFim: _parseDate(json['janela_fim']),
      chegouEm: _parseDate(json['chegou_em']),
      levantadaEm: _parseDate(json['levantada_em']),
      levantadaPor: json['levantada_por'] as String?,
      multaAplicadaEm: _parseDate(json['multa_aplicada_em']),
      multaValorKz: json['multa_valor_kz']?.toString(),
      multaEstado: json['multa_estado'] as String?,
      multaPagoVia: json['multa_pago_via'] as String?,
      multaPagoEm: _parseDate(json['multa_pago_em']),
      multaPagoObservacoes: json['multa_pago_observacoes'] as String?,
      fotoPath: json['foto_path'] as String?,
      fraccao: json['fraccao'] != null
          ? FraccaoEncomenda.fromJson(json['fraccao'] as Map<String, dynamic>)
          : null,
      condomino: json['condomino'] != null
          ? CondominoEncomenda.fromJson(json['condomino'] as Map<String, dynamic>)
          : null,
      recebidaPor: json['recebida_por'] is Map
          ? UserBasic.fromJson(json['recebida_por'] as Map<String, dynamic>)
          : (json['recebida_por'] is String
              ? UserBasic(id: 0, name: json['recebida_por'] as String)
              : null),
      entreguePor: json['entregue_por'] is Map
          ? UserBasic.fromJson(json['entregue_por'] as Map<String, dynamic>)
          : (json['entregue_por'] is String
              ? UserBasic(id: 0, name: json['entregue_por'] as String)
              : null),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  // Helpers para UI
  bool get temMultaPendente => estado == 'multa_aplicada' && multaEstado == 'pendente';
  bool get podeSerCancelada => estado == 'aguarda_chegada';
  bool get foiEntregue => estado == 'entregue';
}

class FraccaoEncomenda {
  final int id;
  final String identificador;

  FraccaoEncomenda({required this.id, required this.identificador});

  factory FraccaoEncomenda.fromJson(Map<String, dynamic> json) =>
      FraccaoEncomenda(
        id: json['id'] as int,
        identificador: json['identificador'] as String,
      );
}

class CondominoEncomenda {
  final int id;
  final String nomeCompleto;

  CondominoEncomenda({required this.id, required this.nomeCompleto});

  factory CondominoEncomenda.fromJson(Map<String, dynamic> json) =>
      CondominoEncomenda(
        id: json['id'] as int,
        nomeCompleto: json['nome_completo'] as String,
      );
}

class UserBasic {
  final int id;
  final String name;

  UserBasic({required this.id, required this.name});

  factory UserBasic.fromJson(Map<String, dynamic> json) => UserBasic(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );
}
