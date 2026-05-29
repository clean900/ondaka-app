import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/config/api_config.dart';
import '../models/anuncio.dart';

class AnuncioCard extends StatelessWidget {
  final Anuncio anuncio;
  final VoidCallback onTap;

  const AnuncioCard({super.key, required this.anuncio, required this.onTap});

  String _preco() {
    if (anuncio.preco == null) return 'A combinar';
    final v = anuncio.preco!;
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$s Kz';
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = anuncio.fotos.isNotEmpty;
    final vendido = anuncio.estadoVenda == 'vendido';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem ou placeholder
            AspectRatio(
              aspectRatio: 1.3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (temFoto)
                    Image.network(
                      anuncio.fotos.first.urlCompleta(ApiConfig.baseUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _placeholder(),
                    )
                  else
                    _placeholder(),
                  if (vendido)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text('VENDIDO',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(anuncio.titulo,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                  const SizedBox(height: 4),
                  Text(_preco(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.cyan)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(anuncio.isProduto ? Icons.inventory_2_outlined : Icons.handyman_outlined,
                          size: 12, color: AppColors.textFaint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(anuncio.categoria?.nome ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
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

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceHi,
      alignment: Alignment.center,
      child: Icon(
        anuncio.isProduto ? Icons.image_outlined : Icons.handyman_outlined,
        size: 36,
        color: AppColors.textFaint,
      ),
    );
  }
}
