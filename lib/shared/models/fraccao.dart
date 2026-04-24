/// Representa uma fracção (apartamento) dentro de um condomínio.
///
/// Modelo simplificado — só os campos usados pela UI do módulo Visitor.
class Fraccao {
  final int id;
  final int empresaGestoraId;
  final int condominioId;
  final String identificador;
  final int? piso;
  final int? numeroQuartos;

  Fraccao({
    required this.id,
    required this.empresaGestoraId,
    required this.condominioId,
    required this.identificador,
    this.piso,
    this.numeroQuartos,
  });

  factory Fraccao.fromJson(Map<String, dynamic> json) {
    return Fraccao(
      id: json['id'] as int,
      empresaGestoraId: json['empresa_gestora_id'] as int,
      condominioId: json['condominio_id'] as int,
      identificador: json['identificador'] as String,
      piso: json['piso'] as int?,
      numeroQuartos: json['numero_quartos'] as int?,
    );
  }

  /// Label curto para UI: "Fracção 2B" ou "Fracção 2B (Piso 1)".
  String get label {
    if (piso != null) {
      return 'Fracção $identificador (Piso $piso)';
    }
    return 'Fracção $identificador';
  }
}
