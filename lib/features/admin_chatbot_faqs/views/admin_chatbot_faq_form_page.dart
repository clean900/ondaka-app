import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';

import '../controllers/admin_chatbot_faq_controller.dart';
import '../models/chatbot_faq_admin.dart';
import '../widgets/tag_input_field.dart';

class AdminChatbotFaqFormPage extends StatefulWidget {
  final ChatbotFaqAdmin? faq;

  const AdminChatbotFaqFormPage({super.key, this.faq});

  @override
  State<AdminChatbotFaqFormPage> createState() => _AdminChatbotFaqFormPageState();
}

class _AdminChatbotFaqFormPageState extends State<AdminChatbotFaqFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _perguntaController = TextEditingController();
  final _respostaController = TextEditingController();
  final _categoriaCustomController = TextEditingController();

  String _categoriaSelecionada = '';
  bool _usaCategoriaCustom = false;
  String _formato = 'markdown';
  bool _activa = true;
  List<String> _palavrasChave = [];
  bool _showPreview = false;

  late final AdminChatbotFaqController _controller;
  bool get _isEditing => widget.faq != null;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminChatbotFaqController>();

    if (widget.faq != null) {
      final faq = widget.faq!;
      _perguntaController.text = faq.pergunta;
      _respostaController.text = faq.resposta;
      _formato = faq.formato;
      _activa = faq.activa;
      _palavrasChave = List.from(faq.palavrasChave);

      final cat = faq.categoria ?? '';
      if (cat.isNotEmpty && !_controller.categoriasExistentes.contains(cat)) {
        _usaCategoriaCustom = true;
        _categoriaCustomController.text = cat;
      } else {
        _categoriaSelecionada = cat;
      }
    }
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    _respostaController.dispose();
    _categoriaCustomController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final categoria = _usaCategoriaCustom
        ? _categoriaCustomController.text.trim()
        : _categoriaSelecionada;

    final categoriaFinal = categoria.isEmpty ? null : categoria;

    bool sucesso;
    if (_isEditing) {
      sucesso = await _controller.editar(
        faq: widget.faq!,
        pergunta: _perguntaController.text.trim(),
        resposta: _respostaController.text,
        categoria: categoriaFinal,
        palavrasChave: _palavrasChave,
        formato: _formato,
        activa: _activa,
      );
    } else {
      sucesso = await _controller.criar(
        pergunta: _perguntaController.text.trim(),
        resposta: _respostaController.text,
        categoria: categoriaFinal,
        palavrasChave: _palavrasChave,
        formato: _formato,
        activa: _activa,
      );
    }

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'FAQ actualizada.' : 'FAQ criada.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.error.value ?? 'Erro ao guardar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar FAQ' : 'Nova FAQ'),
        actions: [
          Obx(() => TextButton.icon(
                onPressed: _controller.saving.value ? null : _guardar,
                icon: _controller.saving.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_controller.saving.value ? 'A guardar...' : 'Guardar'),
              )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoria(),
              const SizedBox(height: 16),
              _buildPergunta(),
              const SizedBox(height: 16),
              _buildPalavrasChave(),
              const SizedBox(height: 16),
              _buildResposta(),
              const SizedBox(height: 16),
              if (_showPreview) ...[_buildPreview(), const SizedBox(height: 16)],
              _buildFormatoEActiva(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categoria', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        if (!_usaCategoriaCustom)
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: _categoriaSelecionada.isEmpty ? null : _categoriaSelecionada,
                      hint: const Text('— Sem categoria —'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('— Sem categoria —')),
                        ..._controller.categoriasExistentes.map(
                          (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                        ),
                      ],
                      onChanged: (value) => setState(() => _categoriaSelecionada = value ?? ''),
                    )),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => setState(() {
                  _usaCategoriaCustom = true;
                  _categoriaSelecionada = '';
                }),
                child: const Text('+ Outra'),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _categoriaCustomController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nova categoria...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => setState(() {
                  _usaCategoriaCustom = false;
                  _categoriaCustomController.clear();
                }),
                child: const Text('Cancelar'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPergunta() {
    return TextFormField(
      controller: _perguntaController,
      maxLength: 500,
      decoration: const InputDecoration(
        labelText: 'Pergunta *',
        border: OutlineInputBorder(),
        hintText: 'Ex: A piscina abre a que horas?',
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Pergunta obrigatória' : null,
    );
  }

  Widget _buildPalavrasChave() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tag, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Palavras-chave (ajuda o chatbot a encontrar)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TagInputField(
          tags: _palavrasChave,
          onChanged: (tags) => setState(() => _palavrasChave = tags),
        ),
      ],
    );
  }

  Widget _buildResposta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Resposta * (${_formato == 'markdown' ? 'Markdown' : 'Texto'})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showPreview = !_showPreview),
              icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility, size: 14),
              label: Text(_showPreview ? 'Ocultar preview' : 'Ver preview'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _respostaController,
          maxLines: 8,
          minLines: 6,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: _formato == 'markdown'
                ? '**Resposta com Markdown**\n\n- Lista\n- Outra dica\n\n> Bloco importante'
                : 'Resposta em texto simples.',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Resposta obrigatória' : null,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          onChanged: (_) {
            if (_showPreview) setState(() {}); // Refresh preview
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.05),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview:',
            style: TextStyle(fontSize: 11, color: Colors.cyan, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (_formato == 'markdown')
            MarkdownBody(
              data: _respostaController.text.isEmpty ? '*(vazio)*' : _respostaController.text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 13),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                blockquote: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                blockquoteDecoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.cyan.shade300, width: 4)),
                  color: Colors.cyan.withValues(alpha: 0.05),
                ),
                blockquotePadding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
              ),
            )
          else
            Text(
              _respostaController.text.isEmpty ? '(vazio)' : _respostaController.text,
              style: const TextStyle(fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildFormatoEActiva() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Formato', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _formato,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'markdown', child: Text('Markdown (recomendado)')),
                  DropdownMenuItem(value: 'texto', child: Text('Texto simples')),
                ],
                onChanged: (v) => setState(() => _formato = v ?? 'markdown'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _activa,
                      onChanged: (v) => setState(() => _activa = v ?? true),
                    ),
                    const Expanded(child: Text('Activa', style: TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
