import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input de chips para palavras-chave.
/// Adicionar: Enter ou vírgula
/// Remover: clique no X ou Backspace com input vazio
class TagInputField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final int maxTags;
  final int maxTagLength;
  final String hintText;

  const TagInputField({
    super.key,
    required this.tags,
    required this.onChanged,
    this.maxTags = 10,
    this.maxTagLength = 50,
    this.hintText = 'Ex: piscina, horário, reserva',
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _controller.text.trim().toLowerCase();
    if (tag.isEmpty) return;
    if (widget.tags.contains(tag)) {
      _controller.clear();
      return;
    }
    if (widget.tags.length >= widget.maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo ${widget.maxTags} palavras-chave.')),
      );
      return;
    }
    if (tag.length > widget.maxTagLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Palavra muito longa (max ${widget.maxTagLength} caracteres).')),
      );
      return;
    }

    widget.onChanged([...widget.tags, tag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty &&
        widget.tags.isNotEmpty) {
      // Remove última tag
      widget.onChanged(widget.tags.sublist(0, widget.tags.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...widget.tags.map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _removeTag(tag),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: _onKey,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLength: widget.maxTagLength,
                    decoration: InputDecoration(
                      hintText: widget.tags.isEmpty
                          ? widget.hintText
                          : 'Adicionar mais...',
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14),
                    inputFormatters: [
                      // Adicionar quando vírgula
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        if (newValue.text.endsWith(',')) {
                          _controller.text = newValue.text.substring(0, newValue.text.length - 1);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _addTag();
                          });
                          return oldValue;
                        }
                        return newValue;
                      }),
                    ],
                    onSubmitted: (_) => _addTag(),
                    onEditingComplete: () {
                      _addTag();
                      _focusNode.requestFocus();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.tags.length}/${widget.maxTags} palavras. Enter ou vírgula para adicionar.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
