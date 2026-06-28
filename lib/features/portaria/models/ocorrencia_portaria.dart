/// Ocorrência de portaria (add-on livro_ocorrencias).
class OcorrenciaPortaria {
  final int id;
  final String tipo; // observacao | incidente | alerta
  final String descricao;
  final String? fotoPath;
  final DateTime criadaEm;
  final DateTime? resolvidaEm;
  final String? guardaNome;

  OcorrenciaPortaria({
    required this.id,
    required this.tipo,
    required this.descricao,
    this.fotoPath,
    required this.criadaEm,
    this.resolvidaEm,
    this.guardaNome,
  });

  bool get estaAberta => resolvidaEm == null;

  String? get fotoUrl =>
      (fotoPath != null && fotoPath!.isNotEmpty) ? 'https://ondaka.ao/ficheiros/$fotoPath' : null;

  String get tipoLabel => switch (tipo) {
        'incidente' => 'Incidente',
        'alerta' => 'Alerta',
        _ => 'Observação',
      };

  factory OcorrenciaPortaria.fromJson(Map<String, dynamic> json) {
    final guarda = json['guarda'] as Map<String, dynamic>?;
    return OcorrenciaPortaria(
      id: json['id'] as int,
      tipo: (json['tipo'] as String?) ?? 'observacao',
      descricao: json['descricao'] as String,
      fotoPath: json['foto_path'] as String?,
      criadaEm: DateTime.parse(json['created_at'] as String).toLocal(),
      resolvidaEm: json['resolvida_em'] != null
          ? DateTime.parse(json['resolvida_em'] as String).toLocal()
          : null,
      guardaNome: guarda?['name']?.toString(),
    );
  }
}
