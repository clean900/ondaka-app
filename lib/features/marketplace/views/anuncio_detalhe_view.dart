import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/config/api_config.dart';
import '../models/anuncio.dart';
import '../repositories/marketplace_repository.dart';

class AnuncioDetalheView extends StatefulWidget {
  final int anuncioId;
  const AnuncioDetalheView({super.key, required this.anuncioId});

  @override
  State<AnuncioDetalheView> createState() => _AnuncioDetalheViewState();
}

class _AnuncioDetalheViewState extends State<AnuncioDetalheView> {
  final _repo = MarketplaceRepository();
  Anuncio? _anuncio;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final a = await _repo.detalhe(widget.anuncioId);
      setState(() { _anuncio = a; _loading = false; });
    } catch (e) {
      setState(() { _erro = 'Não foi possível carregar o anúncio.'; _loading = false; });
    }
  }

  String _preco(Anuncio a) {
    if (a.preco == null) return 'Preço a combinar';
    final s = a.preco!.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$s Kz';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Anúncio'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        actions: [
          if (_anuncio != null)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Denunciar',
              onPressed: () => _abrirDenuncia(_anuncio!),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: AppColors.textMuted)))
              : _conteudo(_anuncio!),
    );
  }

  Widget _conteudo(Anuncio a) {
    return ListView(
      children: [
        if (a.fotos.isNotEmpty)
          SizedBox(
            height: 260,
            child: PageView(
              children: a.fotos
                  .map((f) => Image.network(
                        f.urlCompleta(ApiConfig.baseUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.surfaceHi,
                          child: const Icon(Icons.image_outlined, size: 48, color: AppColors.textFaint),
                        ),
                      ))
                  .toList(),
            ),
          )
        else
          Container(
            height: 200, color: AppColors.surfaceHi,
            alignment: Alignment.center,
            child: Icon(a.isProduto ? Icons.image_outlined : Icons.handyman_outlined,
                size: 56, color: AppColors.textFaint),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _badge(a.isProduto ? 'Produto' : 'Serviço', AppColors.purple),
                  const SizedBox(width: 8),
                  if (a.estadoVenda != 'disponivel')
                    _badge(a.estadoVendaLabel, AppColors.warning),
                ],
              ),
              const SizedBox(height: 12),
              Text(a.titulo,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textMain)),
              const SizedBox(height: 6),
              Text(_preco(a),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.cyan)),
              const SizedBox(height: 8),
              if (a.categoria != null)
                Text(a.categoria!.nome, style: const TextStyle(fontSize: 13, color: AppColors.textFaint)),
              if (a.descricao != null && a.descricao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(a.descricao!, style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5)),
              ],
              const SizedBox(height: 20),
              if (a.nomeExibicao != null && a.nomeExibicao!.isNotEmpty)
                Row(children: [
                  const Icon(Icons.person_outline, size: 18, color: AppColors.textFaint),
                  const SizedBox(width: 8),
                  Text(a.nomeExibicao!, style: const TextStyle(fontSize: 14, color: AppColors.textMain)),
                ]),
              const SizedBox(height: 16),
              const Text('Contacto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMain)),
              const SizedBox(height: 10),
              if (a.contactoTelefone != null && a.contactoTelefone!.isNotEmpty)
                _contacto(Icons.phone, 'Telefone', a.contactoTelefone!),
              if (a.contactoWhatsapp != null && a.contactoWhatsapp!.isNotEmpty)
                _contacto(Icons.chat, 'WhatsApp', a.contactoWhatsapp!),
              if (a.contactoEmail != null && a.contactoEmail!.isNotEmpty)
                _contacto(Icons.mail_outline, 'Email', a.contactoEmail!),
              if ((a.contactoTelefone ?? '').isEmpty &&
                  (a.contactoWhatsapp ?? '').isEmpty &&
                  (a.contactoEmail ?? '').isEmpty)
                const Text('Sem contacto indicado.', style: TextStyle(color: AppColors.textFaint)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(String txt, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(txt, style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _contacto(IconData icon, String label, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.cyan),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
              Text(valor, style: const TextStyle(fontSize: 14, color: AppColors.textMain)),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirDenuncia(Anuncio a) {
    final motivoCtrl = TextEditingController();
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Denunciar anúncio',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textMain)),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Motivo da denúncia',
                  hintStyle: const TextStyle(color: AppColors.textFaint),
                  filled: true, fillColor: AppColors.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final motivo = motivoCtrl.text.trim();
                    if (motivo.isEmpty) return;
                    Get.back();
                    try {
                      await _repo.denunciar(a.id, motivo, null);
                      Get.snackbar('Obrigado', 'A denúncia foi enviada à equipa ONDAKA.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.surface, colorText: AppColors.textMain);
                    } catch (e) {
                      Get.snackbar('Erro', 'Não foi possível enviar.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFFE24B4A), colorText: const Color(0xFFFFFFFF));
                    }
                  },
                  child: const Text('Enviar denúncia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
