/// Saldo agregado do extracto do condómino.
///
/// Vem do endpoint GET /api/extracto/saldo.
/// Os valores monetários vêm como strings (decimais) — convertemos para
/// double apenas quando precisamos de fazer aritmética/visualização.
class ExtractoSaldo {
  final double totalEmDivida;
  final double totalEmAtraso;
  final int numeroLancamentosEmDivida;
  final int numeroLancamentosEmAtraso;
  final Map<String, double> porTipo;

  ExtractoSaldo({
    required this.totalEmDivida,
    required this.totalEmAtraso,
    required this.numeroLancamentosEmDivida,
    required this.numeroLancamentosEmAtraso,
    required this.porTipo,
  });

  factory ExtractoSaldo.fromJson(Map<String, dynamic> json) {
    final porTipoRaw = json['por_tipo'] is Map ? json['por_tipo'] as Map<String, dynamic> : <String, dynamic>{};
    final porTipo = porTipoRaw.map(
      (k, v) => MapEntry(k, double.tryParse(v.toString()) ?? 0.0),
    );

    return ExtractoSaldo(
      totalEmDivida: double.tryParse(json['total_em_divida'].toString()) ?? 0.0,
      totalEmAtraso: double.tryParse(json['total_em_atraso'].toString()) ?? 0.0,
      numeroLancamentosEmDivida:
          (json['numero_lancamentos_em_divida'] as num?)?.toInt() ?? 0,
      numeroLancamentosEmAtraso:
          (json['numero_lancamentos_em_atraso'] as num?)?.toInt() ?? 0,
      porTipo: porTipo,
    );
  }

  bool get estaEmDia => totalEmDivida <= 0;
  bool get temAtraso => totalEmAtraso > 0;
}
