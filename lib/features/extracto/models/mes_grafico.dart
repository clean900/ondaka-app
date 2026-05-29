/// Entrada mensal do gráfico de barras do Dashboard mobile.
///
/// Vem do endpoint GET /api/extracto/grafico-mensal.
/// Devolve sempre 12 entradas (do mês mais antigo para o mais recente).
class MesGrafico {
  final String mes;        // ex: "junho"
  final String mesCurto;   // ex: "Jun"
  final int ano;
  final double pago;
  final double emAberto;

  MesGrafico({
    required this.mes,
    required this.mesCurto,
    required this.ano,
    required this.pago,
    required this.emAberto,
  });

  factory MesGrafico.fromJson(Map<String, dynamic> json) {
    return MesGrafico(
      mes: json['mes']?.toString() ?? '',
      mesCurto: json['mes_curto']?.toString() ?? '',
      ano: (json['ano'] as num?)?.toInt() ?? 0,
      pago: (json['pago'] as num?)?.toDouble() ?? 0.0,
      emAberto: (json['em_aberto'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Total do mês (para escala do gráfico).
  double get total => pago + emAberto;
}
