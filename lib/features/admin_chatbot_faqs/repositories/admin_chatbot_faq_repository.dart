import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/chatbot_faq_admin.dart';

class AdminChatbotFaqRepository {
  final Dio _dio;

  AdminChatbotFaqRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista todas as FAQs do condomínio activo + categorias existentes.
  Future<({List<ChatbotFaqAdmin> faqs, List<String> categorias})> listar() async {
    final response = await _dio.get(
      '/admin/chatbot/faqs',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    final data = response.data as Map<String, dynamic>;

    // Backend pode devolver dados via Inertia (props) ou JSON puro
    final faqsJson = (data['faqs'] ?? data['data']) as List<dynamic>? ?? [];
    final catJson = (data['categoriasExistentes'] ?? []) as List<dynamic>;

    final faqs = faqsJson
        .map((j) => ChatbotFaqAdmin.fromJson(j as Map<String, dynamic>))
        .toList();
    final categorias = catJson.map((c) => c.toString()).toList();

    return (faqs: faqs, categorias: categorias);
  }

  /// Cria nova FAQ.
  Future<ChatbotFaqAdmin> criar({
    required String pergunta,
    required String resposta,
    String? categoria,
    List<String> palavrasChave = const [],
    String formato = 'markdown',
    bool activa = true,
  }) async {
    final response = await _dio.post(
      '/admin/chatbot/faqs',
      data: {
        'pergunta': pergunta,
        'resposta': resposta,
        'categoria': categoria,
        'palavras_chave': palavrasChave,
        'formato': formato,
        'activa': activa,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ChatbotFaqAdmin.fromJson(data['faq'] as Map<String, dynamic>);
  }

  /// Edita FAQ.
  Future<ChatbotFaqAdmin> editar({
    required int id,
    required String pergunta,
    required String resposta,
    String? categoria,
    List<String> palavrasChave = const [],
    String formato = 'markdown',
    required bool activa,
  }) async {
    final response = await _dio.put(
      '/admin/chatbot/faqs/$id',
      data: {
        'pergunta': pergunta,
        'resposta': resposta,
        'categoria': categoria,
        'palavras_chave': palavrasChave,
        'formato': formato,
        'activa': activa,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ChatbotFaqAdmin.fromJson(data['faq'] as Map<String, dynamic>);
  }

  /// Toggle activa/inactiva.
  Future<ChatbotFaqAdmin> toggle(int id) async {
    final response = await _dio.post('/admin/chatbot/faqs/$id/toggle');
    final data = response.data as Map<String, dynamic>;
    return ChatbotFaqAdmin.fromJson(data['faq'] as Map<String, dynamic>);
  }

  /// Elimina FAQ.
  Future<void> eliminar(int id) async {
    await _dio.delete('/admin/chatbot/faqs/$id');
  }

  /// Reordena FAQs.
  Future<void> reordenar(List<int> ids) async {
    await _dio.post(
      '/admin/chatbot/faqs/reorder',
      data: {'ids': ids},
    );
  }
}
