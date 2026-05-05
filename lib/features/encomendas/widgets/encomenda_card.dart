import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/encomenda.dart';

/// Card visual para uma encomenda. Mostra estado, descrição, remetente e datas.
/// Pode ser tap-able (callback opcional). Mostra botão "Cancelar" se a encomenda
/// for um pré-anúncio cancelável.
class EncomendaCard extends StatelessWidget {
  final Encomenda encomenda;
  final VoidCallback? onTap;
  final VoidCallback? onCancelar;
  final bool isCancelando;

  const EncomendaCard({
    super.key,
    required this.encomenda,
    this.onTap,
    this.onCancelar,
    this.isCancelando = false,
  });

  @override
  Widget build(BuildContext context) {
    final estadoCfg = _estadoConfig(encomenda.estado);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha topo: descrição + badge estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        color: AppColors.purple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          encomenda.descricao,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (encomenda.remetente != null &&
                            encomenda.remetente!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            encomenda.remetente!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: estadoCfg.label,
                    color: estadoCfg.color,
                    icon: estadoCfg.icon,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Linha meta — fracção + data registo
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (encomenda.fraccao != null)
                    _MetaItem(
                      icon: Icons.home_outlined,
                      text: 'Imóvel ${encomenda.fraccao!.identificador}',
                    ),
                  _MetaItem(
                    icon: Icons.event,
                    text: _formatDate(encomenda.createdAt),
                  ),
                  if (encomenda.chegouEm != null)
                    _MetaItem(
                      icon: Icons.local_shipping_outlined,
                      text: 'Chegou ${_formatDate(encomenda.chegouEm!)}',
                    ),
                ],
              ),

              // Linha multa (se aplicável)
              if (encomenda.multaValorKz != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Multa ${_formatKz(encomenda.multaValorKz!)} Kz (${encomenda.multaEstado ?? ''})',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.dangerSoft,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],

              // Botão cancelar (só para pré-anúncios)
              if (onCancelar != null && encomenda.podeSerCancelada) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isCancelando ? null : onCancelar,
                    icon: isCancelando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(isCancelando ? 'A cancelar...' : 'Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerSoft,
                      side: BorderSide(
                          color: AppColors.danger.withOpacity(0.4)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes ${hora}:${min}';
  }

  String _formatKz(String valor) {
    final n = double.tryParse(valor) ?? 0;
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  _EstadoConfig _estadoConfig(String estado) {
    switch (estado) {
      case 'aguarda_chegada':
        return _EstadoConfig('Aguarda', AppColors.info, Icons.schedule);
      case 'aguarda_levantamento':
        return _EstadoConfig('Na portaria', AppColors.cyan,
            Icons.inventory_2_outlined);
      case 'entregue':
        return _EstadoConfig('Entregue', AppColors.success,
            Icons.check_circle_outline);
      case 'multa_aplicada':
        return _EstadoConfig('Multa', AppColors.danger,
            Icons.warning_amber_outlined);
      case 'cancelada':
        return _EstadoConfig('Cancelada', AppColors.textMuted,
            Icons.cancel_outlined);
      default:
        return _EstadoConfig(estado, AppColors.textMuted, Icons.help_outline);
    }
  }
}

class _EstadoConfig {
  final String label;
  final Color color;
  final IconData icon;
  _EstadoConfig(this.label, this.color, this.icon);
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 13),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
