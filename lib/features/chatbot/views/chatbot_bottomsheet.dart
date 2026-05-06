import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chatbot_controller.dart';
import '../models/chatbot_mensagem.dart';
import '../widgets/chatbot_bubble.dart';
import '../widgets/chatbot_input.dart';
import '../widgets/chatbot_typing.dart';

class ChatbotBottomsheet extends StatelessWidget {
  final String? userName;

  const ChatbotBottomsheet({super.key, this.userName});

  /// Helper estático para abrir o bottomsheet.
  static Future<void> abrir(BuildContext context, {String? userName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChatbotBottomsheet(userName: userName),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inicializar/recuperar controller
    final ctrl = Get.put(ChatbotController(), tag: 'chatbot');
    final primeiroNome = userName?.split(' ').first;
    ctrl.iniciar(primeiroNome);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            _header(context),
            Expanded(child: _mensagens(ctrl, scrollController)),
            ChatbotInput(
              onEnviar: (texto) async {
                await ctrl.enviarPergunta(texto);
              },
              loading: ctrl.loading.value,
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF06B6D4).withValues(alpha: 0.1),
            const Color(0xFFA855F7).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Assistente ONDAKA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Sempre a postos para ajudar',
                  style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Color(0xFFA1A1AA)),
          ),
        ],
      ),
    );
  }

  Widget _mensagens(ChatbotController ctrl, ScrollController scrollController) {
    return Obx(() {
      // Auto-scroll quando há novas mensagens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });

      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          for (var i = 0; i < ctrl.mensagens.length; i++) ...[
            ChatbotBubble(mensagem: ctrl.mensagens[i]),

            // Sugestões iniciais (depois do welcome)
            if (i == 0 &&
                ctrl.mensagens[i].id == 'welcome' &&
                ctrl.mensagens.length == 1)
              _sugestoes(ctrl),

            // Perguntas relacionadas
            if (ctrl.mensagens[i].relacionadas.isNotEmpty)
              _relacionadas(ctrl, ctrl.mensagens[i]),
          ],
          if (ctrl.loading.value) const ChatbotTyping(),
        ],
      );
    });
  }

  Widget _sugestoes(ChatbotController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sugestões:',
            style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
          ),
          const SizedBox(height: 8),
          ...ctrl.sugestoesIniciais.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => ctrl.enviarPergunta(s),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF27272A)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _relacionadas(ChatbotController ctrl, ChatbotMensagem mensagem) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quer saber também:',
            style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
          ),
          const SizedBox(height: 4),
          ...mensagem.relacionadas.map(
            (p) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => ctrl.clicarPergunta(p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Text(
                    '↳ ${p.pergunta}',
                    style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
