import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/afiliados_controller.dart';
import '../widgets/afiliados_ui.dart';

/// Separador «Apresentação»: a apresentação comercial do programa dentro da
/// app, para o afiliado a mostrar a quem está a tentar trazer — sem sair do
/// sítio nem andar à procura de um ficheiro no email.
///
/// Porquê um WebView e não os ecrãs reescritos em Flutter: a apresentação é um
/// documento autónomo, com estilo próprio, navegação própria e os quatro
/// tutoriais em vídeo lá dentro. Refazê-la em Dart obrigava a repetir o
/// trabalho de cada vez que ela mudasse, e ela muda sempre que os preços ou as
/// regras mudam. Assim há um só original, o mesmo que o painel web mostra.
///
/// NÃO CARREGA SOZINHO. São 220 KB de HTML com vídeo lá dentro, e numa rede
/// móvel isso gasta-se a quem só queria ver as comissões. Carrega quando
/// alguém diz que quer ver.
class ApresentacaoTab extends StatefulWidget {
  final AfiliadosController c;

  const ApresentacaoTab({super.key, required this.c});

  @override
  State<ApresentacaoTab> createState() => _ApresentacaoTabState();
}

class _ApresentacaoTabState extends State<ApresentacaoTab> {
  bool _abrir = false;
  bool _aCarregar = true;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final url = widget.c.painel.value?.apresentacaoUrl ?? '';

      if (widget.c.aCarregarPainel.value && widget.c.painel.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (url.isEmpty) {
        return const Vazio(
          icone: Icons.slideshow_outlined,
          titulo: 'Apresentação indisponível',
          texto: 'A apresentação do programa ainda não está publicada. '
              'Entretanto pode mostrá-la a partir do portal web, em '
              'ondaka.ao/afiliado/apresentacao.',
        );
      }

      return Column(
        children: [
          _Barra(
            url: url,
            aberta: _abrir,
            onPartilhar: () => widget.c.partilhar(
              'Programa de Afiliados da ONDAKA — 6% a 10% de comissão: $url',
            ),
          ),
          Expanded(child: _abrir ? _visor(url) : _convite(url)),
        ],
      );
    });
  }

  /// Antes de carregar: o que é, e um botão. Nunca um ecrã em branco à espera.
  Widget _convite(String url) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.slideshow_outlined, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 18),
          const Text(
            'A apresentação do programa',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMain, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Oito secções que explicam como se ganha, o que conta para comissão, os '
            'escalões, as regras e como se recebe — com quatro tutoriais em vídeo lá '
            'dentro. É o que deve mostrar a quem quiser trazer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, height: 1.55),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => setState(() => _abrir = true),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('Abrir aqui'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _abrirFora(url),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Abrir no browser'),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wifi_tethering, size: 16, color: AppColors.textFaint),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Traz vídeo: com dados móveis, prefira vê-la com Wi-Fi.',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _visor(String url) {
    if (_erro != null) {
      return CaixaErro(
        mensagem: _erro!,
        onTentar: () async => setState(() {
          _erro = null;
          _aCarregar = true;
          _abrir = false;
        }),
      );
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            // A apresentação toca vídeo: sem isto, no iOS abria em ecrã cheio
            // e saía da app a cada tutorial.
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: true,
            useHybridComposition: true,
            transparentBackground: true,
            supportZoom: true,
          ),
          onLoadStop: (_, _) {
            if (mounted) setState(() => _aCarregar = false);
          },
          onReceivedError: (_, _, erro) {
            if (mounted) {
              setState(() {
                _aCarregar = false;
                _erro = 'Não foi possível abrir a apresentação (${erro.description}). '
                    'Verifique a ligação e tente outra vez.';
              });
            }
          },
        ),
        if (_aCarregar)
          const ColoredBox(
            color: AppColors.bgDark,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _abrirFora(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Get.snackbar('Não consegui abrir', 'Nenhum browser respondeu ao endereço.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _Barra extends StatelessWidget {
  final String url;
  final bool aberta;
  final VoidCallback onPartilhar;

  const _Barra({required this.url, required this.aberta, required this.onPartilhar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Mostre-a a quem quiser trazer',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
          IconButton(
            onPressed: onPartilhar,
            icon: const Icon(Icons.share, size: 18),
            color: AppColors.cyan,
            tooltip: 'Partilhar o endereço',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
