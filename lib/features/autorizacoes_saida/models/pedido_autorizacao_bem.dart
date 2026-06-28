/// Pedido de autorização de saída de um bem não declarado à entrada
/// (add-on Controlo de Bens). Mostrado ao condómino do imóvel para aprovar/recusar.
class PedidoAutorizacaoBem {
  final int itemId;
  final int visitaId;
  final String descricao;
  final int quantidade;
  final String? identificador;
  final String? fotoPath;
  final String visitanteNome;
  final String fraccaoLabel;

  PedidoAutorizacaoBem({
    required this.itemId,
    required this.visitaId,
    required this.descricao,
    required this.quantidade,
    this.identificador,
    this.fotoPath,
    required this.visitanteNome,
    required this.fraccaoLabel,
  });

  String? get fotoUrl =>
      (fotoPath != null && fotoPath!.isNotEmpty) ? 'https://ondaka.ao/ficheiros/$fotoPath' : null;

  factory PedidoAutorizacaoBem.fromJson(Map<String, dynamic> json) {
    final visita = json['visita'] as Map<String, dynamic>?;
    final visitante = visita?['visitante'] as Map<String, dynamic>?;
    final fraccao = visita?['fraccao'] as Map<String, dynamic>?;

    final ident = fraccao?['identificador']?.toString();
    return PedidoAutorizacaoBem(
      itemId: json['id'] as int,
      visitaId: (json['visita_id'] as num?)?.toInt() ?? (visita?['id'] as num?)?.toInt() ?? 0,
      descricao: json['descricao'] as String,
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 1,
      identificador: json['identificador'] as String?,
      fotoPath: json['foto_entrada_path'] as String?,
      visitanteNome: visitante?['nome']?.toString() ?? 'Visitante',
      fraccaoLabel: ident != null ? 'Imóvel $ident' : 'Imóvel',
    );
  }
}
