import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chatbot_mensagem.dart';

class ChatbotBubble extends StatelessWidget {
  final ChatbotMensagem mensagem;

  const ChatbotBubble({super.key, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final isUser = mensagem.tipo == TipoMensagem.user;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _avatar(true),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF06B6D4).withValues(alpha: 0.25)
                      : const Color(0xFF27272A),
                  border: isUser
                      ? Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4))
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mensagem.perguntaTitulo != null && !isUser) ...[
                      Text(
                        mensagem.perguntaTitulo!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF22D3EE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    _conteudo(theme),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _avatar(false),
        ],
      ),
    );
  }

  Widget _conteudo(ThemeData theme) {
    if (mensagem.formato == 'markdown') {
      return MarkdownBody(
        data: mensagem.texto,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
          strong: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          em: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
          listBullet:
              const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
          code: const TextStyle(
            fontSize: 12,
            color: Color(0xFF22D3EE),
            backgroundColor: Color(0xFF18181B),
            fontFamily: 'monospace',
          ),
          blockquote: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
          blockquoteDecoration: BoxDecoration(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.05),
            border: const Border(
              left: BorderSide(color: Color(0xFF06B6D4), width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.all(8),
          a: const TextStyle(
            color: Color(0xFF22D3EE),
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (text, href, title) {},
      );
    }
    return Text(
      mensagem.texto,
      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
    );
  }

  Widget _avatar(bool isBot) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: isBot
            ? const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isBot ? null : const Color(0xFF3F3F46),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isBot ? Icons.smart_toy_outlined : Icons.person_outline,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
