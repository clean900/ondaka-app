import 'package:flutter/material.dart';

enum OrdemEstado {
  pendente('pendente', 'Pendente', Color(0xFFF59E0B)),
  emRevisao('em_revisao', 'Em revisão', Color(0xFF3B82F6)),
  aprovada('aprovada', 'Aprovada', Color(0xFF10B981)),
  rejeitada('rejeitada', 'Rejeitada', Color(0xFFEF4444)),
  cancelada('cancelada', 'Cancelada', Color(0xFF6B7280));

  final String slug;
  final String label;
  final Color cor;

  const OrdemEstado(this.slug, this.label, this.cor);

  static OrdemEstado fromString(String value) {
    return OrdemEstado.values.firstWhere(
      (e) => e.slug == value,
      orElse: () => OrdemEstado.pendente,
    );
  }
}

class Ordem {
  final int id;
  final String numero;
  final String? tipoItem;
  final String? descricaoItem;
  final double valorBase;
  final double valorActivacao;
  final double valorIva;
  final double valorTotal;
  final OrdemEstado estado;
  final DateTime? prazoPagamento;
  final DateTime? aprovadaEm;
  final DateTime? rejeitadaEm;
  final DateTime? canceladaEm;
  final String? motivoRejeicao;
  final String? notasCliente;
  final String? numeroFactura;
  final DateTime createdAt;

  Ordem({
    required this.id,
    required this.numero,
    this.tipoItem,
    this.descricaoItem,
    required this.valorBase,
    required this.valorActivacao,
    required this.valorIva,
    required this.valorTotal,
    required this.estado,
    this.prazoPagamento,
    this.aprovadaEm,
    this.rejeitadaEm,
    this.canceladaEm,
    this.motivoRejeicao,
    this.notasCliente,
    this.numeroFactura,
    required this.createdAt,
  });

  factory Ordem.fromJson(Map<String, dynamic> json) {
    return Ordem(
      id: json['id'] as int,
      numero: json['numero'] as String,
      tipoItem: json['tipo_item'] as String?,
      descricaoItem: json['descricao_item'] as String?,
      valorBase: _toDouble(json['valor_base']),
      valorActivacao: _toDouble(json['valor_activacao']),
      valorIva: _toDouble(json['valor_iva']),
      valorTotal: _toDouble(json['valor_total']),
      estado: OrdemEstado.fromString(json['estado'] as String),
      prazoPagamento: json['prazo_pagamento'] != null
          ? DateTime.parse(json['prazo_pagamento'] as String).toLocal()
          : null,
      aprovadaEm: json['aprovada_em'] != null
          ? DateTime.parse(json['aprovada_em'] as String).toLocal()
          : null,
      rejeitadaEm: json['rejeitada_em'] != null
          ? DateTime.parse(json['rejeitada_em'] as String).toLocal()
          : null,
      canceladaEm: json['cancelada_em'] != null
          ? DateTime.parse(json['cancelada_em'] as String).toLocal()
          : null,
      motivoRejeicao: json['motivo_rejeicao'] as String?,
      notasCliente: json['notas_cliente'] as String?,
      numeroFactura: json['numero_factura'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
