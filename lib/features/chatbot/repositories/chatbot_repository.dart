import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/chatbot_pergunta.dart';

class ChatbotRespostaCompleta {
  final ChatbotPergunta? resposta;
  final List<ChatbotPergunta> relacionadas;
  final String? mensagem;

  ChatbotRespostaCompleta({
    this.resposta,
    this.relacionadas = const [],
    this.mensagem,
  });

  factory ChatbotRespostaCompleta.fromJson(Map<String, dynamic> json) {
    final respostaJson = json['resposta'];
    final relacionadasJson = json['relacionadas'] as List<dynamic>?;

    return ChatbotRespostaCompleta(
      resposta: respostaJson != null
          ? ChatbotPergunta.fromJson(respostaJson as Map<String, dynamic>)
          : null,
      relacionadas: (relacionadasJson ?? [])
          .map((j) => ChatbotPergunta.fromJson(j as Map<String, dynamic>))
          .toList(),
      mensagem: json['message'] as String?,
    );
  }
}

class ChatbotRepository {
  final Dio _dio;

  ChatbotRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista perguntas do Assistente ONDAKA (filtradas por role do user).
  Future<List<ChatbotPergunta>> listarOndaka({String? termo}) async {
    final response = await _dio.get(
      '/chatbot/ondaka',
      queryParameters: termo != null && termo.isNotEmpty ? {'q': termo} : null,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((j) => ChatbotPergunta.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Lista FAQs do Assistente Condomínio.
  Future<List<ChatbotPergunta>> listarCondominio({String? termo}) async {
    final response = await _dio.get(
      '/chatbot/condominio',
      queryParameters: termo != null && termo.isNotEmpty ? {'q': termo} : null,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((j) => ChatbotPergunta.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Envia uma pergunta livre e recebe melhor resposta + relacionadas.
  Future<ChatbotRespostaCompleta> perguntar(String texto) async {
    final response = await _dio.post(
      '/chatbot/perguntar',
      data: {'texto': texto},
    );
    return ChatbotRespostaCompleta.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
