import 'chatbot_pergunta.dart';

enum TipoMensagem { bot, user }

class ChatbotMensagem {
  final String id;
  final TipoMensagem tipo;
  final String texto;
  final String formato; // 'texto' ou 'markdown'
  final String? perguntaTitulo;
  final List<ChatbotPergunta> relacionadas;

  ChatbotMensagem({
    required this.id,
    required this.tipo,
    required this.texto,
    this.formato = 'texto',
    this.perguntaTitulo,
    this.relacionadas = const [],
  });
}
