class Familiar {
  final int id;
  final String nome;
  final String? parentesco;
  final String? telefone;
  final String? email;
  final List<String> acessos;
  final bool ativo;
  final bool temConta;

  Familiar({
    required this.id,
    required this.nome,
    this.parentesco,
    this.telefone,
    this.email,
    required this.acessos,
    required this.ativo,
    required this.temConta,
  });

  factory Familiar.fromJson(Map<String, dynamic> json) {
    return Familiar(
      id: json['id'] as int,
      nome: json['nome'] as String,
      parentesco: json['parentesco'] as String?,
      telefone: json['telefone'] as String?,
      email: json['email'] as String?,
      acessos: (json['acessos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ativo: json['ativo'] as bool? ?? true,
      temConta: json['tem_conta'] as bool? ?? false,
    );
  }
}

// Etiquetas legíveis para cada acesso (PT-AO)
const Map<String, String> kAcessoLabels = {
  'avisos': 'Avisos',
  'portaria': 'Portaria e encomendas',
  'visitas': 'Visitas',
  'pedidos': 'Pedidos de intervenção',
  'sos': 'SOS / Emergência',
  'reservas': 'Reservas de espaços',
  'marketplace': 'Serviços / Marketplace',
  'equipa': 'Equipa do condomínio',
};
