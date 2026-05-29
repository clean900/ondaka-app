/// Contactos de suporte da empresa gestora associada ao condómino.
///
/// Vem do endpoint GET /api/empresa-gestora/contactos.
class ContactosEmpresa {
  final String nome;
  final String? logotipoUrl;
  final String? email;
  final String? telefone;
  final String? whatsapp;
  final String? morada;
  final String? horarioAtendimento;
  final bool configurado;

  ContactosEmpresa({
    required this.nome,
    this.logotipoUrl,
    this.email,
    this.telefone,
    this.whatsapp,
    this.morada,
    this.horarioAtendimento,
    required this.configurado,
  });

  factory ContactosEmpresa.fromJson(Map<String, dynamic> json) {
    return ContactosEmpresa(
      nome: json['nome']?.toString() ?? '',
      logotipoUrl: json['logotipo_url']?.toString(),
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      morada: json['morada']?.toString(),
      horarioAtendimento: json['horario_atendimento']?.toString(),
      configurado: json['configurado'] == true,
    );
  }

  /// Tem pelo menos 1 canal disponível?
  bool get temAlgumCanal => configurado;
}
