import 'package:flutter/material.dart';

class ChatbotInput extends StatefulWidget {
  final void Function(String) onEnviar;
  final bool loading;

  const ChatbotInput({
    super.key,
    required this.onEnviar,
    this.loading = false,
  });

  @override
  State<ChatbotInput> createState() => _ChatbotInputState();
}

class _ChatbotInputState extends State<ChatbotInput> {
  final TextEditingController _controller = TextEditingController();
  bool _temTexto = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final temTexto = _controller.text.trim().isNotEmpty;
      if (temTexto != _temTexto) {
        setState(() => _temTexto = temTexto);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleEnviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty || widget.loading) return;
    widget.onEnviar(texto);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  border: Border.all(color: const Color(0xFF3F3F46)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !widget.loading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleEnviar(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Escreva a sua pergunta...',
                    hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _temTexto && !widget.loading ? _handleEnviar : null,
              child: AnimatedOpacity(
                opacity: _temTexto && !widget.loading ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
