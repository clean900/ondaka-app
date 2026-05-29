double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class ReservaEspaco {
  final int id;
  final String nome;
  final String? descricao;
  final String horaAbertura;
  final String horaFecho;
  final int duracaoMinHoras;
  final int duracaoMaxHoras;
  final int antecedenciaMinHoras;
  final int antecedenciaMaxDias;
  final bool temCaucao;
  final double valorCaucao;

  ReservaEspaco({
    required this.id,
    required this.nome,
    this.descricao,
    required this.horaAbertura,
    required this.horaFecho,
    required this.duracaoMinHoras,
    required this.duracaoMaxHoras,
    required this.antecedenciaMinHoras,
    required this.antecedenciaMaxDias,
    required this.temCaucao,
    required this.valorCaucao,
  });

  factory ReservaEspaco.fromJson(Map<String, dynamic> j) => ReservaEspaco(
        id: j['id'] as int,
        nome: j['nome'] as String,
        descricao: j['descricao'] as String?,
        horaAbertura: (j['hora_abertura'] as String).substring(0, 5),
        horaFecho: (j['hora_fecho'] as String).substring(0, 5),
        duracaoMinHoras: _toInt(j['duracao_min_horas']),
        duracaoMaxHoras: _toInt(j['duracao_max_horas']),
        antecedenciaMinHoras: _toInt(j['antecedencia_min_horas']),
        antecedenciaMaxDias: _toInt(j['antecedencia_max_dias']),
        temCaucao: j['tem_caucao'] == true || j['tem_caucao'] == 1,
        valorCaucao: _toDouble(j['valor_caucao']),
      );
}

class MinhaReserva {
  final int id;
  final int espacoId;
  final String data;
  final String horaInicio;
  final String horaFim;
  final String estado;
  final String? motivo;
  final bool caucaoPaga;
  final String? comprovativoCaucao;
  final String espacoNome;
  final bool espacoTemCaucao;
  final double espacoValorCaucao;

  MinhaReserva({
    required this.id,
    required this.espacoId,
    required this.data,
    required this.horaInicio,
    required this.horaFim,
    required this.estado,
    this.motivo,
    required this.caucaoPaga,
    this.comprovativoCaucao,
    required this.espacoNome,
    required this.espacoTemCaucao,
    required this.espacoValorCaucao,
  });

  factory MinhaReserva.fromJson(Map<String, dynamic> j) {
    final esp = (j['espaco'] as Map<String, dynamic>? ?? const {});
    return MinhaReserva(
      id: j['id'] as int,
      espacoId: j['espaco_id'] as int,
      data: (j['data'] as String).substring(0, 10),
      horaInicio: (j['hora_inicio'] as String).substring(0, 5),
      horaFim: (j['hora_fim'] as String).substring(0, 5),
      estado: j['estado'] as String? ?? 'pendente',
      motivo: j['motivo'] as String?,
      caucaoPaga: j['caucao_paga'] == true || j['caucao_paga'] == 1,
      comprovativoCaucao: j['comprovativo_caucao'] as String?,
      espacoNome: esp['nome'] as String? ?? 'Espaço',
      espacoTemCaucao: esp['tem_caucao'] == true || esp['tem_caucao'] == 1,
      espacoValorCaucao: _toDouble(esp['valor_caucao']),
    );
  }
}
