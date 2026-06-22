/// Passe de visitante (prestador/trabalhador) do condómino.
class Passe {
  final int id;
  final String tipoAcesso;
  final String nomeVisitante;
  final String estado; // pendente | aprovado | recusado | expirada
  final DateTime? validaDesde;
  final DateTime? validaAte;
  final String? pdfUrl; // presente quando aprovado

  const Passe({
    required this.id,
    required this.tipoAcesso,
    required this.nomeVisitante,
    required this.estado,
    this.validaDesde,
    this.validaAte,
    this.pdfUrl,
  });

  factory Passe.fromJson(Map<String, dynamic> j) => Passe(
        id: j['id'] as int,
        tipoAcesso: j['tipo_acesso']?.toString() ?? 'prestador',
        nomeVisitante: j['nome_visitante']?.toString() ?? '',
        estado: j['estado']?.toString() ?? 'pendente',
        validaDesde: j['valida_desde'] != null ? DateTime.tryParse(j['valida_desde'].toString()) : null,
        validaAte: j['valida_ate'] != null ? DateTime.tryParse(j['valida_ate'].toString()) : null,
        pdfUrl: j['pdf_url']?.toString(),
      );

  bool get aprovado => estado == 'aprovado';
  bool get pendente => estado == 'pendente';
}
