class Faq {
  final int id;
  final String categoria;
  final String pergunta;
  final String resposta;
  final int utilSim;
  final int utilNao;

  Faq({
    required this.id,
    required this.categoria,
    required this.pergunta,
    required this.resposta,
    required this.utilSim,
    required this.utilNao,
  });

  factory Faq.fromJson(Map<String, dynamic> json) {
    return Faq(
      id: json['id'] as int,
      categoria: json['categoria'] as String? ?? 'geral',
      pergunta: json['pergunta'] as String? ?? '',
      resposta: json['resposta'] as String? ?? '',
      utilSim: json['util_sim'] as int? ?? 0,
      utilNao: json['util_nao'] as int? ?? 0,
    );
  }

  /// Label legível da categoria (espelha as do backend FaqController).
  String get categoriaLabel {
    const labels = {
      'geral': 'Geral',
      'financeiro': 'Financeiro',
      'manutencao': 'Manutenção',
      'assembleias': 'Assembleias',
      'seguranca': 'Segurança',
      'contactos': 'Contactos',
    };
    return labels[categoria] ?? categoria;
  }
}
