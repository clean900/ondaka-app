import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../app/theme/app_colors.dart';

/// Abre a sala de vídeo (video.ondaka.ao, já com token JWT) DENTRO da app,
/// num WebView interno — sem sair para o browser. Concede câmara/mic ao Jitsi.
class JitsiWebViewView extends StatefulWidget {
  final String url;
  final String titulo;
  const JitsiWebViewView({super.key, required this.url, this.titulo = 'Sala virtual'});

  @override
  State<JitsiWebViewView> createState() => _JitsiWebViewViewState();
}

class _JitsiWebViewViewState extends State<JitsiWebViewView> {
  bool _carregando = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.titulo),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Sair da sala',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              javaScriptEnabled: true,
              useHybridComposition: true,
              iframeAllow: 'camera; microphone',
              iframeAllowFullscreen: true,
            ),
            onPermissionRequest: (controller, request) async {
              // Concede câmara/microfone ao Jitsi dentro do WebView.
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
            onLoadStop: (controller, url) {
              if (mounted) setState(() => _carregando = false);
            },
          ),
          if (_carregando)
            const ColoredBox(
              color: AppColors.bgDark,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
