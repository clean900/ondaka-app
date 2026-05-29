import 'package:get/get.dart';

import '../models/chatbot_faq_admin.dart';
import '../repositories/admin_chatbot_faq_repository.dart';

class AdminChatbotFaqController extends GetxController {
  final AdminChatbotFaqRepository _repository;

  AdminChatbotFaqController({AdminChatbotFaqRepository? repository})
      : _repository = repository ?? AdminChatbotFaqRepository();

  // Estado observável
  final RxList<ChatbotFaqAdmin> faqs = <ChatbotFaqAdmin>[].obs;
  final RxList<String> categoriasExistentes = <String>[].obs;
  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  /// Carrega lista de FAQs do servidor.
  Future<void> carregar() async {
    loading.value = true;
    error.value = null;

    try {
      final r = await _repository.listar();
      faqs.assignAll(r.faqs);
      categoriasExistentes.assignAll(r.categorias);
    } catch (e) {
      error.value = 'Erro ao carregar FAQs: $e';
    } finally {
      loading.value = false;
    }
  }

  /// Cria nova FAQ.
  Future<bool> criar({
    required String pergunta,
    required String resposta,
    String? categoria,
    List<String> palavrasChave = const [],
    String formato = 'markdown',
    bool activa = true,
  }) async {
    saving.value = true;
    error.value = null;

    try {
      final faq = await _repository.criar(
        pergunta: pergunta,
        resposta: resposta,
        categoria: categoria,
        palavrasChave: palavrasChave,
        formato: formato,
        activa: activa,
      );
      faqs.add(faq);
      // Adicionar nova categoria à lista se for nova
      if (categoria != null &&
          categoria.isNotEmpty &&
          !categoriasExistentes.contains(categoria)) {
        categoriasExistentes.add(categoria);
        categoriasExistentes.sort();
      }
      return true;
    } catch (e) {
      error.value = 'Erro ao criar: $e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Edita FAQ existente.
  Future<bool> editar({
    required ChatbotFaqAdmin faq,
    required String pergunta,
    required String resposta,
    String? categoria,
    required List<String> palavrasChave,
    required String formato,
    required bool activa,
  }) async {
    saving.value = true;
    error.value = null;

    try {
      final actualizada = await _repository.editar(
        id: faq.id,
        pergunta: pergunta,
        resposta: resposta,
        categoria: categoria,
        palavrasChave: palavrasChave,
        formato: formato,
        activa: activa,
      );
      final idx = faqs.indexWhere((f) => f.id == faq.id);
      if (idx >= 0) {
        faqs[idx] = actualizada;
      }
      // Adicionar nova categoria à lista
      if (categoria != null &&
          categoria.isNotEmpty &&
          !categoriasExistentes.contains(categoria)) {
        categoriasExistentes.add(categoria);
        categoriasExistentes.sort();
      }
      return true;
    } catch (e) {
      error.value = 'Erro ao editar: $e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Toggle activa/inactiva.
  Future<void> toggle(ChatbotFaqAdmin faq) async {
    try {
      final actualizada = await _repository.toggle(faq.id);
      final idx = faqs.indexWhere((f) => f.id == faq.id);
      if (idx >= 0) {
        faqs[idx] = actualizada;
      }
    } catch (e) {
      error.value = 'Erro ao alterar estado: $e';
    }
  }

  /// Elimina FAQ.
  Future<bool> eliminar(ChatbotFaqAdmin faq) async {
    try {
      await _repository.eliminar(faq.id);
      faqs.removeWhere((f) => f.id == faq.id);
      return true;
    } catch (e) {
      error.value = 'Erro ao eliminar: $e';
      return false;
    }
  }

  /// Reordena FAQs (drag-and-drop).
  Future<void> reordenar(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = faqs.removeAt(oldIndex);
    faqs.insert(newIndex, item);

    // Sincronizar com servidor
    try {
      await _repository.reordenar(faqs.map((f) => f.id).toList());
    } catch (e) {
      error.value = 'Erro ao reordenar: $e';
      // Reverter local — recarregar do servidor
      await carregar();
    }
  }
}
