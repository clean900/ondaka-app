import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/faq.dart';

class FaqRepository {
  final Dio _dio;

  FaqRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista FAQs activas do condomínio do user + globais da empresa.
  Future<List<Faq>> listar() async {
    final response = await _dio.get('/faqs');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((j) => Faq.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Pesquisa textual nas FAQs (mínimo 2 caracteres).
  Future<List<Faq>> buscar(String query) async {
    final response = await _dio.get(
      '/faqs/buscar',
      queryParameters: {'q': query},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((j) => Faq.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Marca uma FAQ como útil (true) ou não útil (false).
  Future<void> marcarUtil(int faqId, bool util) async {
    await _dio.post('/faqs/$faqId/util', data: {'util': util});
  }
}
