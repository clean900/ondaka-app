import 'package:get/get.dart';

import '../models/chatbot_mensagem.dart';
import '../models/chatbot_pergunta.dart';
import '../repositories/chatbot_repository.dart';

class ChatbotController extends GetxController {
  final ChatbotRepository _repository;

  ChatbotController({ChatbotRepository? repository})
      : _repository = repository ?? ChatbotRepository();

  // State observables
  final RxList<ChatbotMensagem> mensagens = <ChatbotMensagem>[].obs;
  final RxBool loading = false.obs;
  final RxString erro = ''.obs;

  final List<String> sugestoesIniciais = const [
    'Como pago a taxa de condomínio?',
    'Como pré-aprovo uma visita?',
    'O que é o Fundo de Reserva?',
    'Como activar o ProxyPay?',
    'O que é o Passe de Visitante?',
    'Como solicitar um passe para um prestador?',
    'O que é a Lista Negra de visitantes?',
    'O que é a Manutenção Preventiva?',
    'Como abro um pedido de intervenção?',
    'Como contactar suporte ONDAKA?',
  ];

  /// Inicializa o chat com mensagem de boas-vindas.
  void iniciar(String? primeiroNome) {
    if (mensagens.isEmpty) {
      mensagens.add(
        ChatbotMensagem(
          id: 'welcome',
          tipo: TipoMensagem.bot,
          texto: primeiroNome != null && primeiroNome.isNotEmpty
              ? 'Olá $primeiroNome! Sobre o que precisa de ajuda?'
              : 'Olá! Sobre o que precisa de ajuda?',
        ),
      );
    }
  }

  /// Limpa o chat (usado quando user fecha o bottomsheet).
  void resetar() {
    mensagens.clear();
    erro.value = '';
  }

  /// Envia uma pergunta livre ao backend.
  Future<void> enviarPergunta(String texto) async {
    final textoTrim = texto.trim();
    if (textoTrim.isEmpty || loading.value) return;

    // Adiciona mensagem do user
    mensagens.add(
      ChatbotMensagem(
        id: 'u-${DateTime.now().millisecondsSinceEpoch}',
        tipo: TipoMensagem.user,
        texto: textoTrim,
      ),
    );
    loading.value = true;
    erro.value = '';

    try {
      final resposta = await _repository.perguntar(textoTrim);

      // Pequeno delay para parecer "a digitar"
      await Future.delayed(const Duration(milliseconds: 600));

      if (resposta.resposta != null) {
        mensagens.add(
          ChatbotMensagem(
            id: 'b-${DateTime.now().millisecondsSinceEpoch}',
            tipo: TipoMensagem.bot,
            texto: resposta.resposta!.resposta,
            formato: resposta.resposta!.formato,
            perguntaTitulo: resposta.resposta!.pergunta,
            relacionadas: resposta.relacionadas,
          ),
        );
      } else {
        mensagens.add(
          ChatbotMensagem(
            id: 'b-${DateTime.now().millisecondsSinceEpoch}',
            tipo: TipoMensagem.bot,
            texto: resposta.mensagem ??
                'Não encontrei uma resposta. Tente reformular ou contacte o suporte.',
          ),
        );
      }
    } catch (e) {
      mensagens.add(
        ChatbotMensagem(
          id: 'b-${DateTime.now().millisecondsSinceEpoch}',
          tipo: TipoMensagem.bot,
          texto: 'Erro de ligação. Tenta novamente.',
        ),
      );
      erro.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /// Helper: clicar numa pergunta relacionada ou sugestão.
  Future<void> clicarPergunta(ChatbotPergunta p) async {
    await enviarPergunta(p.pergunta);
  }
}
