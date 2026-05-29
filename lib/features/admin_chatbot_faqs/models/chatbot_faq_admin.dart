class ChatbotFaqAdmin {
  final int id;
  final int condominioId;
  final String? categoria;
  final String pergunta;
  final String resposta;
  final List<String> palavrasChave;
  final String formato; // 'texto' ou 'markdown'
  final int ordem;
  final bool activa;

  ChatbotFaqAdmin({
    required this.id,
    required this.condominioId,
    this.categoria,
    required this.pergunta,
    required this.resposta,
    this.palavrasChave = const [],
    this.formato = 'markdown',
    this.ordem = 0,
    this.activa = true,
  });

  factory ChatbotFaqAdmin.fromJson(Map<String, dynamic> json) {
    final palavrasJson = json['palavras_chave'];
    List<String> palavras = [];
    if (palavrasJson is List) {
      palavras = palavrasJson.map((e) => e.toString()).toList();
    } else if (palavrasJson is String && palavrasJson.isNotEmpty) {
      // Se vier como string JSON serializada
      try {
        // Pode não ser necessário, mas garantia
        palavras = palavrasJson.split(',').map((s) => s.trim()).toList();
      } catch (_) {}
    }

    return ChatbotFaqAdmin(
      id: json['id'] as int,
      condominioId: json['condominio_id'] as int,
      categoria: json['categoria'] as String?,
      pergunta: json['pergunta'] as String,
      resposta: json['resposta'] as String,
      palavrasChave: palavras,
      formato: (json['formato'] as String?) ?? 'markdown',
      ordem: (json['ordem'] as int?) ?? 0,
      activa: (json['activa'] as bool?) ?? (json['activa'] == 1),
    );
  }

  ChatbotFaqAdmin copyWith({
    int? id,
    String? categoria,
    String? pergunta,
    String? resposta,
    List<String>? palavrasChave,
    String? formato,
    int? ordem,
    bool? activa,
  }) {
    return ChatbotFaqAdmin(
      id: id ?? this.id,
      condominioId: condominioId,
      categoria: categoria ?? this.categoria,
      pergunta: pergunta ?? this.pergunta,
      resposta: resposta ?? this.resposta,
      palavrasChave: palavrasChave ?? this.palavrasChave,
      formato: formato ?? this.formato,
      ordem: ordem ?? this.ordem,
      activa: activa ?? this.activa,
    );
  }
}
