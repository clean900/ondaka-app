import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';

class PopupPublicidade {
  /// Verifica se ha popup ativo e, se ainda nao foi visto hoje, mostra-o.
  static Future<void> verificarEMostrar(BuildContext context) async {
    try {
      final api = Get.find<ApiService>();
      final response = await api.dio.get('/publicidade/popup-ativo');
      final data = response.data['data'];
      if (data == null) return;

      final id = data['id'];
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final chave = 'popup_pub_${id}_$hoje';

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(chave) == true) return; // ja visto hoje

      if (!context.mounted) return;
      await _mostrar(context, data);
      await prefs.setBool(chave, true);
    } catch (_) {
      // silencioso: publicidade nunca deve quebrar a app
    }
  }

  static Future<void> _mostrar(BuildContext context, Map<String, dynamic> p) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p['imagem_url'] != null)
              Image.network(
                p['imagem_url'],
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p['titulo'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (p['mensagem'] != null) ...[
                    const SizedBox(height: 8),
                    Text(p['mensagem'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Fechar', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      if (p['link_url'] != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              final url = Uri.tryParse(p['link_url']);
                              if (url != null) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(p['botao_texto'] ?? 'Saber mais'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
