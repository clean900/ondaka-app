/// Despesa pendente de aprovação pela comissão de moradores.
class DespesaPendente {
  final int id;
  final String? descricao;
  final String? fornecedor;
  final double valor;
  final String? dataDespesa;
  final String? categoria;
  final String? condominio;

  DespesaPendente({
    required this.id,
    this.descricao,
    this.fornecedor,
    this.valor = 0,
    this.dataDespesa,
    this.categoria,
    this.condominio,
  });

  factory DespesaPendente.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;
    return DespesaPendente(
      id: json['id'] as int,
      descricao: json['descricao']?.toString(),
      fornecedor: json['fornecedor']?.toString(),
      valor: toDouble(json['valor']),
      dataDespesa: json['data_despesa']?.toString(),
      categoria: json['categoria']?.toString(),
      condominio: json['condominio']?.toString(),
    );
  }
}
