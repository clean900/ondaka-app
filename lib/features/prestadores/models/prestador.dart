/// Modelo de um prestador.
class Prestador {
  final int id;
  final String nome;
  final String tipo;
  final String? telefone;
  final String? email;
  final String? especialidades;
  final String? fotoPath;
  final double? latitude;
  final double? longitude;
  final double mediaEstrelas;
  final int totalAvaliacoes;
  final bool destacado;
  final bool certificado;
  final double? distanciaKm;

  Prestador({
    required this.id,
    required this.nome,
    required this.tipo,
    this.telefone,
    this.email,
    this.especialidades,
    this.fotoPath,
    this.latitude,
    this.longitude,
    this.mediaEstrelas = 0,
    this.totalAvaliacoes = 0,
    this.destacado = false,
    this.certificado = false,
    this.distanciaKm,
  });

  factory Prestador.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    return Prestador(
      id: json['id'] as int,
      nome: json['nome']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'publico',
      telefone: json['telefone']?.toString(),
      email: json['email']?.toString(),
      especialidades: json['especialidades']?.toString(),
      fotoPath: json['foto_path']?.toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      mediaEstrelas: toDouble(json['media_estrelas']) ?? 0,
      totalAvaliacoes: (json['total_avaliacoes'] as num?)?.toInt() ?? 0,
      destacado: json['destacado'] == true,
      certificado: json['certificado'] == true,
      distanciaKm: toDouble(json['distancia_km']),
    );
  }

  /// URL completa do logo/foto do prestador, ou null se não tiver.
  /// Ficheiros são servidos via /ficheiros/ (não /storage/) — ver CLAUDE.md.
  String? get fotoUrl {
    final p = fotoPath;
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http')) return p;
    final limpo = p.replaceFirst(RegExp(r'^/?storage/'), '').replaceFirst(RegExp(r'^/'), '');
    return 'https://ondaka.ao/ficheiros/$limpo';
  }
}

/// Categoria de prestador.
class PrestadorCategoria {
  final int id;
  final String nome;
  final String slug;
  final String? icone;

  PrestadorCategoria({
    required this.id,
    required this.nome,
    required this.slug,
    this.icone,
  });

  factory PrestadorCategoria.fromJson(Map<String, dynamic> json) {
    return PrestadorCategoria(
      id: json['id'] as int,
      nome: json['nome']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icone: json['icone']?.toString(),
    );
  }
}

/// Avaliação de um prestador.
class AvaliacaoPrestador {
  final int id;
  final int estrelas;
  final String? comentario;
  final String? autorNome;
  final String? createdAt;

  AvaliacaoPrestador({
    required this.id,
    required this.estrelas,
    this.comentario,
    this.autorNome,
    this.createdAt,
  });

  factory AvaliacaoPrestador.fromJson(Map<String, dynamic> json) {
    return AvaliacaoPrestador(
      id: json['id'] as int,
      estrelas: (json['estrelas'] as num?)?.toInt() ?? 0,
      comentario: json['comentario']?.toString(),
      autorNome: json['user']?['name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
