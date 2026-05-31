/// Categoria do marketplace.
class MarketplaceCategoria {
  final int id;
  final String nome;
  final String slug;
  final String? icone;

  MarketplaceCategoria({
    required this.id,
    required this.nome,
    required this.slug,
    this.icone,
  });

  factory MarketplaceCategoria.fromJson(Map<String, dynamic> json) {
    return MarketplaceCategoria(
      id: json['id'] as int,
      nome: json['nome']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icone: json['icone']?.toString(),
    );
  }
}

/// Foto de um anúncio.
class AnuncioFoto {
  final int id;
  final String path;
  final String? url;
  final int ordem;

  AnuncioFoto({required this.id, required this.path, this.url, this.ordem = 0});

  factory AnuncioFoto.fromJson(Map<String, dynamic> json) {
    return AnuncioFoto(
      id: json['id'] as int,
      path: json['path']?.toString() ?? '',
      url: json['url']?.toString(),
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
    );
  }

  /// URL completa da foto. Prefere o campo 'url' (rota Laravel) da API.
  String urlCompleta(String baseUrl) {
    if (url != null && url!.isNotEmpty) return url!;
    if (path.startsWith('http')) return path;
    final b = baseUrl.replaceAll('/api', '');
    return '$b/ficheiros/$path';
  }
}

/// Anúncio do marketplace.
class Anuncio {
  final int id;
  final String tipo; // produto | servico
  final String titulo;
  final String? descricao;
  final double? preco;
  final String visibilidade; // condominio | plataforma
  final String estadoVenda; // disponivel | em_negociacao | vendido | cancelado
  final String? estadoModeracao;
  final String? nomeExibicao;
  final String? contactoTelefone;
  final String? contactoWhatsapp;
  final String? contactoEmail;
  final MarketplaceCategoria? categoria;
  final List<AnuncioFoto> fotos;
  final String? createdAt;

  Anuncio({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.descricao,
    this.preco,
    this.visibilidade = 'condominio',
    this.estadoVenda = 'disponivel',
    this.estadoModeracao,
    this.nomeExibicao,
    this.contactoTelefone,
    this.contactoWhatsapp,
    this.contactoEmail,
    this.categoria,
    this.fotos = const [],
    this.createdAt,
  });

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      id: json['id'] as int,
      tipo: json['tipo']?.toString() ?? 'produto',
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      preco: json['preco'] == null ? null : double.tryParse(json['preco'].toString()),
      visibilidade: json['visibilidade']?.toString() ?? 'condominio',
      estadoVenda: json['estado_venda']?.toString() ?? 'disponivel',
      estadoModeracao: json['estado_moderacao']?.toString(),
      nomeExibicao: json['nome_exibicao']?.toString(),
      contactoTelefone: json['contacto_telefone']?.toString(),
      contactoWhatsapp: json['contacto_whatsapp']?.toString(),
      contactoEmail: json['contacto_email']?.toString(),
      categoria: json['categoria'] != null
          ? MarketplaceCategoria.fromJson(json['categoria'] as Map<String, dynamic>)
          : null,
      fotos: (json['fotos'] as List? ?? [])
          .map((e) => AnuncioFoto.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at']?.toString(),
    );
  }

  bool get isProduto => tipo == 'produto';

  String get estadoVendaLabel {
    switch (estadoVenda) {
      case 'em_negociacao': return 'Em negociação';
      case 'vendido': return 'Vendido';
      case 'cancelado': return 'Cancelado';
      default: return 'Disponível';
    }
  }
}
