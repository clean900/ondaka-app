/// Representa uma pessoa que visita um condomínio.
///
/// Espelha a tabela `visitantes` (cadastro reutilizável) do backend.
class Visitante {
  final int id;
  final int empresaGestoraId;
  final String nome;
  final String? telefone;
  final String? biNumero;
  final String? fotoPath;
  final String? notas;

  Visitante({
    required this.id,
    required this.empresaGestoraId,
    required this.nome,
    this.telefone,
    this.biNumero,
    this.fotoPath,
    this.notas,
  });

  factory Visitante.fromJson(Map<String, dynamic> json) {
    return Visitante(
      id: json['id'] as int,
      empresaGestoraId: json['empresa_gestora_id'] as int,
      nome: json['nome'] as String,
      telefone: json['telefone'] as String?,
      biNumero: json['bi_numero'] as String?,
      fotoPath: json['foto_path'] as String?,
      notas: json['notas'] as String?,
    );
  }
}
