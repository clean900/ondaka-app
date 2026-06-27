/// Item/bem registado à entrada de uma visita (add-on Controlo de Bens).
///
/// Espelha a tabela `visita_itens` do backend. Entra com estado `dentro`;
/// na saída é reconciliado como `saiu` (levou) ou `ficou` (deixou).
class VisitaItem {
  final int id;
  final int visitaId;
  final String descricao;
  final String? categoria;
  final int quantidade;
  final String? identificador;
  final String estado; // dentro | saiu | ficou
  final String? observacoes;

  VisitaItem({
    required this.id,
    required this.visitaId,
    required this.descricao,
    this.categoria,
    required this.quantidade,
    this.identificador,
    required this.estado,
    this.observacoes,
  });

  factory VisitaItem.fromJson(Map<String, dynamic> json) {
    return VisitaItem(
      id: json['id'] as int,
      visitaId: json['visita_id'] as int,
      descricao: json['descricao'] as String,
      categoria: json['categoria'] as String?,
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 1,
      identificador: json['identificador'] as String?,
      estado: (json['estado'] as String?) ?? 'dentro',
      observacoes: json['observacoes'] as String?,
    );
  }

  bool get estaDentro => estado == 'dentro';

  String get estadoLabel => switch (estado) {
        'saiu' => 'Saiu',
        'ficou' => 'Ficou',
        _ => 'Dentro',
      };
}
