import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/prestador.dart';

class PrestadorCard extends StatelessWidget {
  final Prestador prestador;
  final VoidCallback onTap;

  const PrestadorCard({
    super.key,
    required this.prestador,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: prestador.destacado ? AppColors.purple : AppColors.border,
            width: prestador.destacado ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(nome: prestador.nome),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prestador.nome,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (prestador.destacado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Destaque',
                            style: TextStyle(fontSize: 11, color: AppColors.purpleSoft),
                          ),
                        ),
                    ],
                  ),
                  if (prestador.especialidades != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      prestador.especialidades!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        prestador.totalAvaliacoes > 0
                            ? '${prestador.mediaEstrelas} (${prestador.totalAvaliacoes})'
                            : 'Sem avaliações',
                        style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
                      ),
                      if (prestador.distanciaKm != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textFaint),
                        const SizedBox(width: 2),
                        Text(
                          '${prestador.distanciaKm} km',
                          style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nome;
  const _Avatar({required this.nome});

  @override
  Widget build(BuildContext context) {
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
