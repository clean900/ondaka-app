/// Movimento do extracto — pode ser um lançamento (débito) ou pagamento (crédito).
///
/// Vem do endpoint GET /api/extracto.
class Movimento {
  final String tipoMovimento; // 'lancamento' ou 'pagamento'
  final int id;
  final DateTime data;
  final DateTime? dataVencimento;
  final String descricao;
  final String? detalhes;
  final String? tipo; // só para lancamento: quota_base, fundo_reserva, despesa_extra, multa
  final String? metodo; // só para pagamento
  final double valor;
  final double? valorPago;
  final double? valorEmDivida;
  final String sentido; // 'debito' | 'credito'
  final String estado;
  final bool emAtraso;
  final FraccaoMovimento? fraccao;

  Movimento({
    required this.tipoMovimento,
    required this.id,
    required this.data,
    this.dataVencimento,
    required this.descricao,
    this.detalhes,
    this.tipo,
    this.metodo,
    required this.valor,
    this.valorPago,
    this.valorEmDivida,
    required this.sentido,
    required this.estado,
    required this.emAtraso,
    this.fraccao,
  });

  factory Movimento.fromJson(Map<String, dynamic> json) {
    return Movimento(
      tipoMovimento: json['tipo_movimento']?.toString() ?? 'lancamento',
      id: (json['id'] as num).toInt(),
      data: DateTime.parse(json['data'].toString()),
      dataVencimento: json['data_vencimento'] != null
          ? DateTime.tryParse(json['data_vencimento'].toString())
          : null,
      descricao: json['descricao']?.toString() ?? '',
      detalhes: json['detalhes']?.toString(),
      tipo: json['tipo']?.toString(),
      metodo: json['metodo']?.toString(),
      valor: double.tryParse(json['valor'].toString()) ?? 0.0,
      valorPago: json['valor_pago'] != null
          ? double.tryParse(json['valor_pago'].toString())
          : null,
      valorEmDivida: json['valor_em_divida'] != null
          ? double.tryParse(json['valor_em_divida'].toString())
          : null,
      sentido: json['sentido']?.toString() ?? 'debito',
      estado: json['estado']?.toString() ?? '',
      emAtraso: json['em_atraso'] == true,
      fraccao: json['fraccao'] != null
          ? FraccaoMovimento.fromJson(json['fraccao'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isLancamento => tipoMovimento == 'lancamento';
  bool get isPagamento => tipoMovimento == 'pagamento';
  bool get isDebito => sentido == 'debito';
  bool get isCredito => sentido == 'credito';
  bool get foiCancelado => estado == 'cancelado';
  bool get estaEmAberto => estado == 'em_aberto' || estado == 'pago_parcial';
  bool get estaPago => estado == 'pago' || estado == 'confirmado';
}

class FraccaoMovimento {
  final int id;
  final String? identificador;

  FraccaoMovimento({required this.id, this.identificador});

  factory FraccaoMovimento.fromJson(Map<String, dynamic> json) {
    return FraccaoMovimento(
      id: (json['id'] as num).toInt(),
      identificador: json['identificador']?.toString(),
    );
  }
}
