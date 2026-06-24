import 'package:intl/intl.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class Prestacao {
  final int numero;
  final double valor;
  final String dataVencimento;
  final String estado;

  Prestacao({
    required this.numero,
    required this.valor,
    required this.dataVencimento,
    required this.estado,
  });

  /// Data formatada dd/MM/yyyy (a API devolve ISO bruto).
  String get dataVencimentoFmt {
    final d = DateTime.tryParse(dataVencimento);
    return d != null ? DateFormat('dd/MM/yyyy').format(d.toLocal()) : dataVencimento;
  }

  factory Prestacao.fromJson(Map<String, dynamic> j) => Prestacao(
        numero: j['numero'] as int? ?? 0,
        valor: _toDouble(j['valor']),
        dataVencimento: j['data_vencimento']?.toString() ?? '',
        estado: j['estado']?.toString() ?? 'pendente',
      );
}

class Proposta {
  final String autor; // 'condomino' ou 'gestor'
  final int ronda;
  final int numPrestacoes;
  final double valorComJuro;
  final double valorEntrada;
  final String? observacoes;
  final String createdAt;

  Proposta({
    required this.autor,
    required this.ronda,
    required this.numPrestacoes,
    required this.valorComJuro,
    required this.valorEntrada,
    this.observacoes,
    required this.createdAt,
  });

  bool get ehGestor => autor == 'gestor';

  factory Proposta.fromJson(Map<String, dynamic> j) => Proposta(
        autor: j['autor']?.toString() ?? 'condomino',
        ronda: j['ronda'] as int? ?? 0,
        numPrestacoes: j['num_prestacoes'] as int? ?? 0,
        valorComJuro: _toDouble(j['valor_com_juro']),
        valorEntrada: _toDouble(j['valor_entrada']),
        observacoes: j['observacoes']?.toString(),
        createdAt: j['created_at']?.toString() ?? '',
      );
}

class Acordo {
  final int id;
  final double valorTotal;
  final double valorComJuro;
  final double valorEntrada;
  final int numPrestacoes;
  final String estado;
  final int rondasCondomino;
  final int rondasGestor;
  final String? observacoes;
  final List<Prestacao> prestacoes;
  final List<Proposta> propostas;

  Acordo({
    required this.id,
    required this.valorTotal,
    required this.valorComJuro,
    required this.valorEntrada,
    required this.numPrestacoes,
    required this.estado,
    required this.rondasCondomino,
    required this.rondasGestor,
    this.observacoes,
    required this.prestacoes,
    required this.propostas,
  });

  // É a vez do condómino responder?
  bool get aguardaCondomino => estado == 'aguarda_condomino';
  bool get aguardaGestor => estado == 'aguarda_gestor';
  bool get estaAtivo => estado == 'aprovado' || estado == 'em_cumprimento';
  bool get emNegociacao => aguardaCondomino || aguardaGestor;

  // A última proposta (a que está em cima da mesa)
  Proposta? get ultimaProposta => propostas.isNotEmpty ? propostas.last : null;

  factory Acordo.fromJson(Map<String, dynamic> j) => Acordo(
        id: j['id'] as int? ?? 0,
        valorTotal: _toDouble(j['valor_total']),
        valorComJuro: _toDouble(j['valor_com_juro']),
        valorEntrada: _toDouble(j['valor_entrada']),
        numPrestacoes: j['num_prestacoes'] as int? ?? 0,
        estado: j['estado']?.toString() ?? 'pendente',
        rondasCondomino: j['rondas_condomino'] as int? ?? 0,
        rondasGestor: j['rondas_gestor'] as int? ?? 0,
        observacoes: j['observacoes']?.toString(),
        prestacoes: (j['prestacoes'] as List<dynamic>? ?? [])
            .map((p) => Prestacao.fromJson(p as Map<String, dynamic>))
            .toList(),
        propostas: (j['propostas'] as List<dynamic>? ?? [])
            .map((p) => Proposta.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class LimitacaoInfo {
  final bool limitado;
  final int taxasVencidas;
  final int limiar;
  final double totalEmDivida;
  final String mensagem;

  LimitacaoInfo({
    required this.limitado,
    required this.taxasVencidas,
    required this.limiar,
    required this.totalEmDivida,
    required this.mensagem,
  });

  factory LimitacaoInfo.fromJson(Map<String, dynamic> j) => LimitacaoInfo(
        limitado: j['limitado'] == true || j['limitado'] == 1,
        taxasVencidas: j['taxas_vencidas'] as int? ?? 0,
        limiar: j['limiar'] as int? ?? 3,
        totalEmDivida: _toDouble(j['total_em_divida']),
        mensagem: j['mensagem']?.toString() ?? '',
      );
}
