/// Pagamento submetido pelo condómino.
///
/// Reflecte estrutura de POST /api/extracto/pagamentos.
class Pagamento {
  final int id;
  final String referencia;
  final String metodo; // transferencia_bancaria, deposito_bancario, dinheiro, outro
  final double valor;
  final DateTime dataPagamento;
  final String estado; // pendente, em_revisao, confirmado, rejeitado, devolvido
  final DateTime createdAt;

  // Detalhes (opcional, vem em show())
  final String? referenciaExterna;
  final String? bancoOrigem;
  final String? notasCondomino;
  final DateTime? confirmadoEm;
  final DateTime? rejeitadoEm;
  final String? motivoRejeicao;
  final String? comprovativoUrl;
  final String? comprovativoNome;
  final List<ImputacaoPagamento> imputacoes;

  final FraccaoSimples? fraccao;

  Pagamento({
    required this.id,
    required this.referencia,
    required this.metodo,
    required this.valor,
    required this.dataPagamento,
    required this.estado,
    required this.createdAt,
    this.referenciaExterna,
    this.bancoOrigem,
    this.notasCondomino,
    this.confirmadoEm,
    this.rejeitadoEm,
    this.motivoRejeicao,
    this.comprovativoUrl,
    this.comprovativoNome,
    this.imputacoes = const [],
    this.fraccao,
  });

  factory Pagamento.fromJson(Map<String, dynamic> json) {
    final imputacoesJson = (json['imputacoes'] as List?) ?? [];

    return Pagamento(
      id: (json['id'] as num).toInt(),
      referencia: json['referencia']?.toString() ?? '',
      metodo: json['metodo']?.toString() ?? 'outro',
      valor: double.tryParse(json['valor'].toString()) ?? 0.0,
      dataPagamento: DateTime.parse(json['data_pagamento'].toString()),
      estado: json['estado']?.toString() ?? 'pendente',
      createdAt: DateTime.parse(json['created_at'].toString()),
      referenciaExterna: json['referencia_externa']?.toString(),
      bancoOrigem: json['banco_origem']?.toString(),
      notasCondomino: json['notas_condomino']?.toString(),
      confirmadoEm: json['confirmado_em'] != null
          ? DateTime.tryParse(json['confirmado_em'].toString())
          : null,
      rejeitadoEm: json['rejeitado_em'] != null
          ? DateTime.tryParse(json['rejeitado_em'].toString())
          : null,
      motivoRejeicao: json['motivo_rejeicao']?.toString(),
      comprovativoUrl: json['comprovativo_url']?.toString(),
      comprovativoNome: json['comprovativo_nome']?.toString(),
      imputacoes: imputacoesJson
          .cast<Map<String, dynamic>>()
          .map(ImputacaoPagamento.fromJson)
          .toList(),
      fraccao: json['fraccao'] != null
          ? FraccaoSimples.fromJson(json['fraccao'] as Map<String, dynamic>)
          : null,
    );
  }

  // Helpers
  bool get estaPendente => estado == 'pendente' || estado == 'em_revisao';
  bool get estaConfirmado => estado == 'confirmado';
  bool get foiRejeitado => estado == 'rejeitado';
  bool get podeEditar => estaPendente;

  String get metodoLabel {
    switch (metodo) {
      case 'transferencia_bancaria':
        return 'Transferência bancária';
      case 'deposito_bancario':
        return 'Depósito bancário';
      case 'dinheiro':
        return 'Dinheiro';
      case 'proxypay_rps':
        return 'Multicaixa Express';
      default:
        return 'Outro';
    }
  }

  String get estadoLabel {
    switch (estado) {
      case 'pendente':
        return 'Pendente';
      case 'em_revisao':
        return 'Em revisão';
      case 'confirmado':
        return 'Confirmado';
      case 'rejeitado':
        return 'Rejeitado';
      case 'devolvido':
        return 'Devolvido';
      default:
        return estado;
    }
  }
}

class ImputacaoPagamento {
  final int lancamentoId;
  final String? lancamentoDescricao;
  final double valor;

  ImputacaoPagamento({
    required this.lancamentoId,
    this.lancamentoDescricao,
    required this.valor,
  });

  factory ImputacaoPagamento.fromJson(Map<String, dynamic> json) {
    return ImputacaoPagamento(
      lancamentoId: (json['lancamento_id'] as num).toInt(),
      lancamentoDescricao: json['lancamento_descricao']?.toString(),
      valor: double.tryParse(json['valor'].toString()) ?? 0.0,
    );
  }
}

class FraccaoSimples {
  final int id;
  final String? identificador;

  FraccaoSimples({required this.id, this.identificador});

  factory FraccaoSimples.fromJson(Map<String, dynamic> json) {
    return FraccaoSimples(
      id: (json['id'] as num).toInt(),
      identificador: json['identificador']?.toString(),
    );
  }
}
