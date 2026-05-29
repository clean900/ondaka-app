import 'package:flutter/material.dart';

/// Tipos conhecidos de notificação que vêm do backend.
/// O backend devolve string livre em `tipo`; aqui mapeamos para enum com ícone/cor.
/// Tipos desconhecidos caem em [generica].
enum NotificacaoTipo {
  quotaEmitida('quota_emitida', 'Quota emitida', Icons.receipt_long, Color(0xFFF59E0B)),
  pedidoAtribuido('pedido_atribuido', 'Pedido atribuído', Icons.assignment_ind, Color(0xFF3B82F6)),
  pedidoEstado('pedido_estado', 'Pedido actualizado', Icons.update, Color(0xFF8B5CF6)),
  avisoNovo('aviso_novo', 'Novo aviso', Icons.campaign, Color(0xFFEC4899)),
  assembleiaAgendada('assembleia_agendada', 'Assembleia agendada', Icons.event, Color(0xFF10B981)),
  pagamentoConfirmado('pagamento_confirmado', 'Pagamento confirmado', Icons.check_circle, Color(0xFF10B981)),
  pagamentoFalhou('pagamento_falhou', 'Pagamento falhou', Icons.error_outline, Color(0xFFEF4444)),
  generica('generica', 'Notificação', Icons.notifications, Color(0xFF6B7280));

  final String slug;
  final String label;
  final IconData icon;
  final Color cor;

  const NotificacaoTipo(this.slug, this.label, this.icon, this.cor);

  static NotificacaoTipo fromString(String? value) {
    if (value == null) return NotificacaoTipo.generica;
    return NotificacaoTipo.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => NotificacaoTipo.generica,
    );
  }
}

class Notificacao {
  final String id; // UUID (Laravel database channel)
  final NotificacaoTipo tipo;
  final String tipoRaw; // String original do backend (para tipos desconhecidos)
  final String titulo;
  final String mensagem;
  final String? url; // Onde navegar quando o user clica
  final bool lida;
  final DateTime createdAt;
  final String createdHuman; // "há 5 minutos" — já vem formatado do backend

  Notificacao({
    required this.id,
    required this.tipo,
    required this.tipoRaw,
    required this.titulo,
    required this.mensagem,
    this.url,
    required this.lida,
    required this.createdAt,
    required this.createdHuman,
  });

  /// Cria uma cópia com campos alterados (útil para optimistic UI).
  Notificacao copyWith({
    bool? lida,
  }) {
    return Notificacao(
      id: id,
      tipo: tipo,
      tipoRaw: tipoRaw,
      titulo: titulo,
      mensagem: mensagem,
      url: url,
      lida: lida ?? this.lida,
      createdAt: createdAt,
      createdHuman: createdHuman,
    );
  }

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String? ?? 'generica';
    return Notificacao(
      id: json['id'] as String,
      tipo: NotificacaoTipo.fromString(tipoRaw),
      tipoRaw: tipoRaw,
      titulo: json['titulo'] as String? ?? '',
      mensagem: json['mensagem'] as String? ?? '',
      url: json['url'] as String?,
      lida: json['lida'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      createdHuman: json['created_human'] as String? ?? '',
    );
  }
}

/// Resposta completa do endpoint GET /notificacoes.
class NotificacoesPayload {
  final List<Notificacao> notificacoes;
  final int naoLidas;

  NotificacoesPayload({
    required this.notificacoes,
    required this.naoLidas,
  });

  factory NotificacoesPayload.fromJson(Map<String, dynamic> json) {
    final list = json['notificacoes'] as List<dynamic>? ?? [];
    return NotificacoesPayload(
      notificacoes: list
          .map((j) => Notificacao.fromJson(j as Map<String, dynamic>))
          .toList(),
      naoLidas: (json['nao_lidas'] as num?)?.toInt() ?? 0,
    );
  }
}
