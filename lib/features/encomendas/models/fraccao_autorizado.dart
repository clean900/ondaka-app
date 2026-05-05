class FraccaoAutorizado {
  final int id;
  final int? fraccaoId;
  final int? cadastradoPorCondominoId;
  final String nomeCompleto;
  final String? biPassport;
  final String? telefone;
  final String relacao; // conjuge, filho, empregada, familiar, outro
  final String? fotoPath;
  final bool activo;
  final DateTime createdAt;

  FraccaoAutorizado({
    required this.id,
    this.fraccaoId,
    this.cadastradoPorCondominoId,
    required this.nomeCompleto,
    this.biPassport,
    this.telefone,
    required this.relacao,
    this.fotoPath,
    required this.activo,
    required this.createdAt,
  });

  factory FraccaoAutorizado.fromJson(Map<String, dynamic> json) {
    return FraccaoAutorizado(
      id: (json['id'] as num).toInt(),
      fraccaoId: json['fraccao_id'] is num
          ? (json['fraccao_id'] as num).toInt()
          : null,
      cadastradoPorCondominoId: json['cadastrado_por_condomino_id'] is num
          ? (json['cadastrado_por_condomino_id'] as num).toInt()
          : null,
      nomeCompleto: json['nome_completo']?.toString() ?? '',
      biPassport: json['bi_passport']?.toString(),
      telefone: json['telefone']?.toString(),
      relacao: json['relacao']?.toString() ?? 'outro',
      fotoPath: json['foto_path']?.toString(),
      activo: json['activo'] == null
          ? true
          : (json['activo'] is bool
              ? json['activo'] as bool
              : ((json['activo'] as num?)?.toInt() ?? 1) == 1),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get relacaoLabel {
    switch (relacao) {
      case 'conjuge':
        return 'Cônjuge';
      case 'filho':
        return 'Filho/a';
      case 'empregada':
        return 'Empregada';
      case 'familiar':
        return 'Familiar';
      default:
        return 'Outro';
    }
  }
}
