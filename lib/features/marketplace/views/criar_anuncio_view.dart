import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/marketplace_controller.dart';
import '../models/anuncio.dart';
import '../repositories/marketplace_repository.dart';

class CriarAnuncioView extends StatefulWidget {
  final Anuncio? anuncioEditar;
  const CriarAnuncioView({super.key, this.anuncioEditar});

  bool get isEdicao => anuncioEditar != null;

  @override
  State<CriarAnuncioView> createState() => _CriarAnuncioViewState();
}

class _CriarAnuncioViewState extends State<CriarAnuncioView> {
  final _ctrl = Get.put(CriarAnuncioController());
  final _repo = MarketplaceRepository();

  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController();
  final _nomeExib = TextEditingController();
  final _telefone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();

  final List<XFile> _fotos = [];
  final _picker = ImagePicker();

  String _tipo = 'produto';
  String _visibilidade = 'condominio';
  int? _categoriaId;
  List<MarketplaceCategoria> _categorias = [];
  bool _loadingCats = true;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    final a = widget.anuncioEditar;
    if (a != null) {
      _titulo.text = a.titulo;
      _descricao.text = a.descricao ?? '';
      _preco.text = a.preco != null ? a.preco!.toStringAsFixed(0) : '';
      _nomeExib.text = a.nomeExibicao ?? '';
      _telefone.text = a.contactoTelefone ?? '';
      _whatsapp.text = a.contactoWhatsapp ?? '';
      _email.text = a.contactoEmail ?? '';
      _tipo = a.tipo;
      _visibilidade = a.visibilidade;
      _categoriaId = a.categoria?.id;
    }
  }

  Future<void> _carregarCategorias() async {
    try {
      final res = await _repo.listar();
      setState(() { _categorias = res.categorias; _loadingCats = false; });
    } catch (e) {
      setState(() => _loadingCats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(widget.isEdicao ? 'Editar anúncio' : 'Publicar anúncio'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: _loadingCats
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _label('Tipo'),
                Row(children: [
                  _opcao('Produto', _tipo == 'produto', () => setState(() => _tipo = 'produto')),
                  const SizedBox(width: 8),
                  _opcao('Serviço', _tipo == 'servico', () => setState(() => _tipo = 'servico')),
                ]),
                const SizedBox(height: 16),

                _label('Fotos (opcional, até 6)'),
                _seccaoFotos(),
                const SizedBox(height: 16),

                _label('Título *'),
                _campo(_titulo, 'Ex: Sofá de 3 lugares em bom estado'),
                const SizedBox(height: 16),

                _label('Categoria *'),
                _dropdownCategoria(),
                const SizedBox(height: 16),

                _label('Descrição'),
                _campo(_descricao, 'Detalhes do produto ou serviço', linhas: 4),
                const SizedBox(height: 16),

                _label('Preço (Kz) — deixe vazio para "a combinar"'),
                _campo(_preco, 'Ex: 50000', teclado: TextInputType.number),
                const SizedBox(height: 16),

                _label('Visibilidade'),
                Row(children: [
                  _opcao('Só o meu condomínio', _visibilidade == 'condominio',
                      () => setState(() => _visibilidade = 'condominio')),
                  const SizedBox(width: 8),
                  _opcao('Toda a rede', _visibilidade == 'plataforma',
                      () => setState(() => _visibilidade = 'plataforma')),
                ]),
                const SizedBox(height: 20),

                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                const Text('Como o contactam? (privado até você publicar)',
                    style: TextStyle(fontSize: 13, color: AppColors.textFaint)),
                const SizedBox(height: 12),

                _label('Nome a mostrar'),
                _campo(_nomeExib, 'Ex: João M.'),
                const SizedBox(height: 12),
                _label('Telefone'),
                _campo(_telefone, '+244 9XX XXX XXX', teclado: TextInputType.phone),
                const SizedBox(height: 12),
                _label('WhatsApp'),
                _campo(_whatsapp, '+244 9XX XXX XXX', teclado: TextInputType.phone),
                const SizedBox(height: 12),
                _label('Email'),
                _campo(_email, 'opcional@exemplo.ao', teclado: TextInputType.emailAddress),
                const SizedBox(height: 24),

                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: const Color(0xFF001218),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _ctrl.aEnviar.value ? null : _submeter,
                        child: Text(_ctrl.aEnviar.value ? 'A guardar...' : (widget.isEdicao ? 'Guardar alterações' : 'Publicar anúncio'),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Future<void> _submeter() async {
    if (_titulo.text.trim().isEmpty) {
      Get.snackbar('Falta o título', 'Indique um título para o anúncio.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface, colorText: AppColors.textMain);
      return;
    }
    if (_categoriaId == null) {
      Get.snackbar('Falta a categoria', 'Escolha uma categoria.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface, colorText: AppColors.textMain);
      return;
    }

    final dados = <String, dynamic>{
      'categoria_id': _categoriaId,
      'tipo': _tipo,
      'titulo': _titulo.text.trim(),
      'visibilidade': _visibilidade,
      if (_descricao.text.trim().isNotEmpty) 'descricao': _descricao.text.trim(),
      if (_preco.text.trim().isNotEmpty) 'preco': double.tryParse(_preco.text.trim()),
      if (_nomeExib.text.trim().isNotEmpty) 'nome_exibicao': _nomeExib.text.trim(),
      if (_telefone.text.trim().isNotEmpty) 'contacto_telefone': _telefone.text.trim(),
      if (_whatsapp.text.trim().isNotEmpty) 'contacto_whatsapp': _whatsapp.text.trim(),
      if (_email.text.trim().isNotEmpty) 'contacto_email': _email.text.trim(),
    };

    if (widget.isEdicao) {
      try {
        await _repo.editar(widget.anuncioEditar!.id, dados);
        if (_fotos.isNotEmpty) {
          await _repo.uploadFotos(widget.anuncioEditar!.id, _fotos.map((f) => f.path).toList());
        }
        Get.snackbar('Guardado', 'Anúncio actualizado.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF1D9E75), colorText: const Color(0xFFFFFFFF));
        Get.back(result: true);
      } catch (e) {
        Get.snackbar('Erro', 'Não foi possível guardar.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE24B4A), colorText: const Color(0xFFFFFFFF));
      }
      return;
    }

    final anuncio = await _ctrl.criar(dados);
    if (anuncio != null) {
      // Enviar fotos seleccionadas (se houver)
      if (_fotos.isNotEmpty) {
        try {
          await _repo.uploadFotos(anuncio.id, _fotos.map((f) => f.path).toList());
        } catch (e) {
          Get.snackbar('Aviso', 'O anúncio foi criado, mas algumas fotos não subiram.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.surface, colorText: AppColors.textMain);
        }
      }
      Get.back(result: true);
    }
  }

  Future<void> _escolherFotos() async {
    if (_fotos.length >= 6) return;
    final imgs = await _picker.pickMultiImage();
    if (imgs.isNotEmpty) {
      setState(() {
        _fotos.addAll(imgs);
        if (_fotos.length > 6) _fotos.removeRange(6, _fotos.length);
      });
    }
  }

  Widget _seccaoFotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._fotos.asMap().entries.map((e) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(e.value.path),
                          width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, size: 20, color: AppColors.dangerSoft),
                        onPressed: () => setState(() => _fotos.removeAt(e.key)),
                      ),
                    ),
                  ],
                )),
            if (_fotos.length < 6)
              GestureDetector(
                onTap: _escolherFotos,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textFaint),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );

  Widget _campo(TextEditingController c, String hint, {int linhas = 1, TextInputType? teclado}) {
    return TextField(
      controller: c,
      maxLines: linhas,
      keyboardType: teclado,
      style: const TextStyle(color: AppColors.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textFaint),
        filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _opcao(String label, bool activo, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activo ? AppColors.cyan : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activo ? AppColors.cyan : AppColors.border),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: activo ? const Color(0xFF001218) : AppColors.textMuted,
                fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      ),
    );
  }

  Widget _dropdownCategoria() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _categoriaId,
          isExpanded: true,
          dropdownColor: AppColors.surfaceHi,
          hint: const Text('Escolha uma categoria', style: TextStyle(color: AppColors.textFaint)),
          style: const TextStyle(color: AppColors.textMain),
          items: _categorias
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
              .toList(),
          onChanged: (v) => setState(() => _categoriaId = v),
        ),
      ),
    );
  }
}
