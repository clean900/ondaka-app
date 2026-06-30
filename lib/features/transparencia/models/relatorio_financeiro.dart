/// Relatório financeiro de transparência do condomínio (dados agregados),
/// devolvido por GET /api/condomino/relatorio-financeiro.
class RelatorioFinanceiro {
  final String? condominio;
  final int meses;
  final double receita;
  final double despesa;
  final double saldo;
  final num taxaCobranca;
  final double dividaTotal;
  final num fundoReservaPct;
  final num fundoReservaMinLegal;
  final bool fundoReservaCumpre;
  final double saldoDisponivel;
  final double dividaAberto;
  final List<DespesaCategoria> despesasPorCategoria;
  final double despesasTotal;

  RelatorioFinanceiro({
    required this.condominio,
    required this.meses,
    required this.receita,
    required this.despesa,
    required this.saldo,
    required this.taxaCobranca,
    required this.dividaTotal,
    required this.fundoReservaPct,
    required this.fundoReservaMinLegal,
    required this.fundoReservaCumpre,
    required this.saldoDisponivel,
    required this.dividaAberto,
    required this.despesasPorCategoria,
    required this.despesasTotal,
  });

  factory RelatorioFinanceiro.fromJson(Map<String, dynamic> j) {
    final fin = (j['financeiro'] ?? {}) as Map<String, dynamic>;
    final cob = (j['cobranca'] ?? {}) as Map<String, dynamic>;
    final fr = (j['fundo_reserva'] ?? {}) as Map<String, dynamic>;
    final liq = (j['liquidez'] ?? {}) as Map<String, dynamic>;
    final cats = (j['despesas_por_categoria'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(DespesaCategoria.fromJson)
        .toList();

    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;

    return RelatorioFinanceiro(
      condominio: j['condominio'] as String?,
      meses: (j['meses'] as num?)?.toInt() ?? 12,
      receita: d(fin['receita']),
      despesa: d(fin['despesa']),
      saldo: d(fin['saldo']),
      taxaCobranca: (cob['taxa_cobranca'] as num?) ?? 0,
      dividaTotal: d(cob['divida_total']),
      fundoReservaPct: (fr['pct'] as num?) ?? 0,
      fundoReservaMinLegal: (fr['min_legal'] as num?) ?? 10,
      fundoReservaCumpre: (fr['cumpre'] as bool?) ?? false,
      saldoDisponivel: d(liq['saldo_disponivel']),
      dividaAberto: d(liq['divida_aberto']),
      despesasPorCategoria: cats,
      despesasTotal: d(j['despesas_total']),
    );
  }
}

class DespesaCategoria {
  final String categoria;
  final double total;

  DespesaCategoria({required this.categoria, required this.total});

  factory DespesaCategoria.fromJson(Map<String, dynamic> j) => DespesaCategoria(
        categoria: (j['categoria'] as String?) ?? '—',
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );
}
