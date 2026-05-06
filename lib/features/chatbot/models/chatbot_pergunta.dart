class ChatbotPergunta {
  final int id;
  final String pergunta;
  final String resposta;
  final String formato; // 'texto' ou 'markdown'

  ChatbotPergunta({
    required this.id,
    required this.pergunta,
    required this.resposta,
    this.formato = 'texto',
  });

  factory ChatbotPergunta.fromJson(Map<String, dynamic> json) {
    return ChatbotPergunta(
      id: json['id'] as int,
      pergunta: json['pergunta'] as String,
      resposta: json['resposta'] as String,
      formato: (json['formato'] as String?) ?? 'texto',
    );
  }
}
