import 'package:flutter/material.dart';

import '../models/chatbot_faq_admin.dart';

class FaqListTile extends StatelessWidget {
  final ChatbotFaqAdmin faq;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDragHandle;

  const FaqListTile({
    super.key,
    required this.faq,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: faq.activa ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDragHandle) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.drag_handle,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (faq.categoria != null && faq.categoria!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          faq.categoria!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    Text(
                      faq.pergunta,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (faq.palavrasChave.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...faq.palavrasChave.take(3).map(
                                (kw) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    kw,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF0891B2),
                                    ),
                                  ),
                                ),
                              ),
                          if (faq.palavrasChave.length > 3)
                            Text(
                              '+${faq.palavrasChave.length - 3}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  // Toggle
                  IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      faq.activa ? Icons.power_settings_new : Icons.power_off,
                      size: 18,
                      color: faq.activa ? Colors.green : Colors.grey,
                    ),
                    tooltip: faq.activa ? 'Desactivar' : 'Activar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  // Menu (editar/eliminar)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade600),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: Colors.cyan),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
