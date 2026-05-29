/// Um modelo de checklist com os seus itens.
class ChecklistModelo {
  final int id;
  final String nome;
  final String? descricao;
  final String tipo;
  final int? condominioId;
  final List<ChecklistItem> itens;

  ChecklistModelo({
    required this.id,
    required this.nome,
    this.descricao,
    required this.tipo,
    this.condominioId,
    required this.itens,
  });

  factory ChecklistModelo.fromJson(Map<String, dynamic> j) {
    final lista = (j['itens'] as List? ?? []);
    return ChecklistModelo(
      id: j['id'] as int,
      nome: j['nome'] as String,
      descricao: j['descricao'] as String?,
      tipo: j['tipo'] as String? ?? 'outro',
      condominioId: j['condominio_id'] as int?,
      itens: lista.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ChecklistItem {
  final int id;
  final String texto;
  final int ordem;
  final bool obrigatorio;

  ChecklistItem({
    required this.id,
    required this.texto,
    required this.ordem,
    required this.obrigatorio,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> j) {
    return ChecklistItem(
      id: j['id'] as int,
      texto: j['texto'] as String,
      ordem: (j['ordem'] as num?)?.toInt() ?? 0,
      obrigatorio: j['obrigatorio'] == true || j['obrigatorio'] == 1,
    );
  }
}
