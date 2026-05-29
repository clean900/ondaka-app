/// Um pedido de avaliação NPS devolvido pela API.
class NpsPedido {
  final String alvo; // 'condominio' ou 'plataforma'
  final String titulo;
  final String pergunta;
  final String seguimento;

  NpsPedido({
    required this.alvo,
    required this.titulo,
    required this.pergunta,
    required this.seguimento,
  });

  factory NpsPedido.fromJson(Map<String, dynamic> json) => NpsPedido(
        alvo: json['alvo'] as String,
        titulo: json['titulo'] as String? ?? '',
        pergunta: json['pergunta'] as String? ?? '',
        seguimento: json['seguimento'] as String? ?? '',
      );
}
