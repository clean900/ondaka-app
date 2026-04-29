class ProximaAssembleia {
  final int id;
  final String numero;
  final String titulo;
  final DateTime dataAgendada;
  final String modo;

  ProximaAssembleia({
    required this.id,
    required this.numero,
    required this.titulo,
    required this.dataAgendada,
    required this.modo,
  });

  factory ProximaAssembleia.fromJson(Map<String, dynamic> json) {
    return ProximaAssembleia(
      id: json['id'] as int,
      numero: json['numero'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      dataAgendada: DateTime.parse(json['data_agendada'] as String),
      modo: json['modo'] as String? ?? 'presencial',
    );
  }
}

class DashboardData {
  final List<ProximaAssembleia> assembleiasProximas;
  final int avisosNaoLidos;
  final int ticketsAbertos;
  final int visitasProximas;

  DashboardData({
    required this.assembleiasProximas,
    required this.avisosNaoLidos,
    required this.ticketsAbertos,
    required this.visitasProximas,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final list = (json['assembleias_proximas'] as List<dynamic>? ?? [])
        .map((j) => ProximaAssembleia.fromJson(j as Map<String, dynamic>))
        .toList();
    return DashboardData(
      assembleiasProximas: list,
      avisosNaoLidos: json['avisos_nao_lidos'] as int? ?? 0,
      ticketsAbertos: json['tickets_abertos'] as int? ?? 0,
      visitasProximas: json['visitas_proximas'] as int? ?? 0,
    );
  }

  /// Verdadeiro quando não há nada que precise de atenção do user.
  bool get tudoEmDia =>
      assembleiasProximas.isEmpty &&
      avisosNaoLidos == 0 &&
      ticketsAbertos == 0 &&
      visitasProximas == 0;
}
