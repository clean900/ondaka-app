/// Feature/funcionalidade do catálogo ONDAKA.
class CatalogoFeature {
  final String nome;
  final String desc;
  final String estado; // pronto | curso | breve | roadmap
  final String? quando;

  CatalogoFeature({
    required this.nome,
    required this.desc,
    required this.estado,
    this.quando,
  });

  factory CatalogoFeature.fromJson(Map<String, dynamic> json) {
    return CatalogoFeature(
      nome: json['nome']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'roadmap',
      quando: json['quando']?.toString(),
    );
  }

  bool get estaPronto => estado == 'pronto';
  bool get emCurso => estado == 'curso';
  bool get emBreve => estado == 'breve';
  bool get noRoadmap => estado == 'roadmap';
}

/// Categoria de funcionalidades do catálogo.
class CatalogoCategoria {
  final String id;
  final String titulo;
  final String iconName;
  final String cor;
  final String descricao;
  final List<CatalogoFeature> features;

  CatalogoCategoria({
    required this.id,
    required this.titulo,
    required this.iconName,
    required this.cor,
    required this.descricao,
    required this.features,
  });

  factory CatalogoCategoria.fromJson(Map<String, dynamic> json) {
    final featuresRaw = (json['features'] as List? ?? []).cast<Map<String, dynamic>>();
    return CatalogoCategoria(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      iconName: json['iconName']?.toString() ?? 'sparkles',
      cor: json['cor']?.toString() ?? 'cyan',
      descricao: json['descricao']?.toString() ?? '',
      features: featuresRaw.map(CatalogoFeature.fromJson).toList(),
    );
  }

  int get totalFeatures => features.length;
}
