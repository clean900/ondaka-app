/// Documento (modelo) publicado pelo gestor, visível ao condómino.
class Documento {
  final int id;
  final String? categoria;
  final String nome;
  final String? descricao;
  final String url;

  Documento({
    required this.id,
    this.categoria,
    required this.nome,
    this.descricao,
    required this.url,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id: json['id'] as int,
      categoria: json['categoria']?.toString(),
      nome: json['nome']?.toString() ?? 'Documento',
      descricao: json['descricao']?.toString(),
      url: json['url']?.toString() ?? '',
    );
  }

  String get categoriaLabel {
    switch (categoria) {
      case 'contrato':
        return 'Contrato';
      case 'regulamento':
        return 'Regulamento';
      default:
        return 'Outro';
    }
  }
}
