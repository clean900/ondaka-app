/// Modelos do Programa de Afiliados, tal como a API os devolve
/// (`GET /api/afiliado/{resumo,clientes,comissoes,pagamentos}`).
///
/// OS VALORES EM KWANZAS VÊM COMO STRING ("1750000.00"), de propósito: no
/// backend são decimais de base de dados e passar por double perdia cêntimos.
/// Aqui converte-se uma vez, com [_num], e guarda-se em double só para
/// apresentar — nenhuma conta de dinheiro é feita na app.
library;

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
}

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _data(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

/// A ficha do afiliado.
class Afiliado {
  final int id;
  final String codigo;
  final String link;
  final String nome;
  final String estado; // pendente | activo | suspenso | recusado
  final String estadoLabel;
  final String nivel;
  final String nivelLabel;
  final double taxaActualPct;
  final bool taxaManual;
  final String? iban;
  final String? banco;
  final String? titularConta;
  final String? motivoRecusa;
  final String? motivoSuspensao;
  final bool dadosPagamentoCompletos;

  const Afiliado({
    required this.id,
    required this.codigo,
    required this.link,
    required this.nome,
    required this.estado,
    required this.estadoLabel,
    required this.nivel,
    required this.nivelLabel,
    required this.taxaActualPct,
    required this.taxaManual,
    required this.iban,
    required this.banco,
    required this.titularConta,
    required this.motivoRecusa,
    required this.motivoSuspensao,
    required this.dadosPagamentoCompletos,
  });

  bool get activo => estado == 'activo';

  factory Afiliado.fromJson(Map<String, dynamic> j) => Afiliado(
        id: _int(j['id']),
        codigo: (j['codigo'] ?? '').toString(),
        link: (j['link'] ?? '').toString(),
        nome: (j['nome'] ?? '').toString(),
        estado: (j['estado'] ?? '').toString(),
        estadoLabel: (j['estado_label'] ?? '').toString(),
        nivel: (j['nivel'] ?? '').toString(),
        nivelLabel: (j['nivel_label'] ?? '').toString(),
        taxaActualPct: _num(j['taxa_actual_pct']),
        taxaManual: j['taxa_manual_pct'] != null,
        iban: j['iban']?.toString(),
        banco: j['banco']?.toString(),
        titularConta: j['titular_conta']?.toString(),
        motivoRecusa: j['motivo_recusa']?.toString(),
        motivoSuspensao: j['motivo_suspensao']?.toString(),
        dadosPagamentoCompletos: j['dados_pagamento_completos'] == true,
      );
}

/// Um escalão da tabela de comissões (6% desde o 1.º Kz … 10%).
class Escalao {
  final String codigo;
  final String label;
  final double taxaPct;
  final double minVolumeKz;

  const Escalao({
    required this.codigo,
    required this.label,
    required this.taxaPct,
    required this.minVolumeKz,
  });

  factory Escalao.fromJson(Map<String, dynamic> j) => Escalao(
        codigo: (j['codigo'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        taxaPct: _num(j['taxa_pct']),
        minVolumeKz: _num(j['min_volume_kz']),
      );
}

/// O escalão seguinte e quanto falta para lá chegar (null quando já está no topo).
class ProximoNivel {
  final String label;
  final double taxaPct;
  final double minVolumeKz;
  final double faltamKz;

  const ProximoNivel({
    required this.label,
    required this.taxaPct,
    required this.minVolumeKz,
    required this.faltamKz,
  });

  /// Fracção já percorrida até ao escalão seguinte, para a barra de progresso.
  double progresso(double volume12mKz) {
    if (minVolumeKz <= 0) return 0;
    final p = volume12mKz / minVolumeKz;
    return p.isNaN ? 0 : p.clamp(0.0, 1.0);
  }

  static ProximoNivel? fromJson(dynamic v) {
    if (v is! Map) return null;
    final j = v.cast<String, dynamic>();
    return ProximoNivel(
      label: (j['label'] ?? j['codigo'] ?? '').toString(),
      taxaPct: _num(j['taxa_pct']),
      minVolumeKz: _num(j['min_volume_kz']),
      faltamKz: _num(j['faltam_kz']),
    );
  }
}

/// Um mês do gráfico dos últimos doze.
class MesComissao {
  final String label;
  final double totalKz;
  final int n;

  const MesComissao({required this.label, required this.totalKz, required this.n});

  factory MesComissao.fromJson(Map<String, dynamic> j) => MesComissao(
        label: (j['label'] ?? '').toString(),
        totalKz: _num(j['total_kz']),
        n: _int(j['n']),
      );
}

/// Os números do painel.
class ResumoAfiliado {
  final int cliques;
  final int registos;
  final int registosMes;
  final int clientesActivos;
  final int clientesPagantes;
  final double volume12mKz;
  final double taxaPct;
  final ProximoNivel? proximoNivel;
  final double pendenteKz;
  final int pendenteN;
  final double aprovadaKz;
  final int aprovadaN;
  final double pagaKz;
  final int pagaN;
  final double totalGeradoKz;
  final double mesActualKz;
  final double totalPagoLiquidoKz;
  final double pagamentoMinimoKz;
  final int carenciaDias;
  final bool atingeMinimo;
  final List<MesComissao> serie12m;
  final String? ultimoPagamentoNumero;
  final double ultimoPagamentoKz;
  final String? ultimoPagamentoEm;

  const ResumoAfiliado({
    required this.cliques,
    required this.registos,
    required this.registosMes,
    required this.clientesActivos,
    required this.clientesPagantes,
    required this.volume12mKz,
    required this.taxaPct,
    required this.proximoNivel,
    required this.pendenteKz,
    required this.pendenteN,
    required this.aprovadaKz,
    required this.aprovadaN,
    required this.pagaKz,
    required this.pagaN,
    required this.totalGeradoKz,
    required this.mesActualKz,
    required this.totalPagoLiquidoKz,
    required this.pagamentoMinimoKz,
    required this.carenciaDias,
    required this.atingeMinimo,
    required this.serie12m,
    required this.ultimoPagamentoNumero,
    required this.ultimoPagamentoKz,
    required this.ultimoPagamentoEm,
  });

  factory ResumoAfiliado.fromJson(Map<String, dynamic> j) {
    final ult = j['ultimo_pagamento'] as Map?;
    return ResumoAfiliado(
      cliques: _int(j['cliques']),
      registos: _int(j['registos']),
      registosMes: _int(j['registos_mes']),
      clientesActivos: _int(j['clientes_activos']),
      clientesPagantes: _int(j['clientes_pagantes']),
      volume12mKz: _num(j['volume_12m_kz']),
      taxaPct: _num(j['taxa_pct']),
      proximoNivel: ProximoNivel.fromJson(j['proximo_nivel']),
      pendenteKz: _num(j['pendente_kz']),
      pendenteN: _int(j['pendente_n']),
      aprovadaKz: _num(j['aprovada_kz']),
      aprovadaN: _int(j['aprovada_n']),
      pagaKz: _num(j['paga_kz']),
      pagaN: _int(j['paga_n']),
      totalGeradoKz: _num(j['total_gerado_kz']),
      mesActualKz: _num(j['mes_actual_kz']),
      totalPagoLiquidoKz: _num(j['total_pago_liquido_kz']),
      pagamentoMinimoKz: _num(j['pagamento_minimo_kz']),
      carenciaDias: _int(j['carencia_dias']),
      atingeMinimo: j['atinge_minimo'] == true,
      serie12m: ((j['serie_12m'] as List?) ?? [])
          .map((e) => MesComissao.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      ultimoPagamentoNumero: ult?['numero']?.toString(),
      ultimoPagamentoKz: _num(ult?['valor_liquido_kz']),
      ultimoPagamentoEm: ult?['pago_em']?.toString(),
    );
  }
}

/// Os textos prontos a enviar, construídos no servidor (ver AfiliadoService).
class MateriaisAfiliado {
  final String link;
  final String codigo;
  final String whatsapp;
  final String emailAssunto;
  final String emailCorpo;
  final String sms;

  const MateriaisAfiliado({
    required this.link,
    required this.codigo,
    required this.whatsapp,
    required this.emailAssunto,
    required this.emailCorpo,
    required this.sms,
  });

  factory MateriaisAfiliado.fromJson(Map<String, dynamic> j) => MateriaisAfiliado(
        link: (j['link'] ?? '').toString(),
        codigo: (j['codigo'] ?? '').toString(),
        whatsapp: (j['whatsapp'] ?? '').toString(),
        emailAssunto: (j['email_assunto'] ?? '').toString(),
        emailCorpo: (j['email_corpo'] ?? '').toString(),
        sms: (j['sms'] ?? '').toString(),
      );
}

/// Tudo o que `GET /api/afiliado/resumo` devolve.
class PainelAfiliado {
  /// Null quando o utilizador não é afiliado (a adesão faz-se na web).
  final Afiliado? afiliado;
  final ResumoAfiliado? resumo;
  final MateriaisAfiliado? materiais;
  final List<Escalao> escaloes;
  final bool programaActivo;

  /// Endereço da apresentação comercial do programa (o mesmo documento que o
  /// painel web mostra). Vazio enquanto a API não o devolver.
  final String apresentacaoUrl;

  const PainelAfiliado({
    required this.afiliado,
    required this.resumo,
    required this.materiais,
    required this.escaloes,
    required this.programaActivo,
    required this.apresentacaoUrl,
  });

  factory PainelAfiliado.fromJson(Map<String, dynamic> j) {
    final cfg = (j['config'] as Map?)?.cast<String, dynamic>() ?? const {};
    final af = j['afiliado'];
    return PainelAfiliado(
      afiliado: af is Map ? Afiliado.fromJson(af.cast<String, dynamic>()) : null,
      resumo: j['resumo'] is Map
          ? ResumoAfiliado.fromJson((j['resumo'] as Map).cast<String, dynamic>())
          : null,
      materiais: j['materiais'] is Map
          ? MateriaisAfiliado.fromJson((j['materiais'] as Map).cast<String, dynamic>())
          : null,
      escaloes: ((cfg['escaloes'] as List?) ?? [])
          .map((e) => Escalao.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      programaActivo: (cfg['programa_activo'] ?? j['programa_activo']) == true,
      apresentacaoUrl: (j['apresentacao_url'] ?? '').toString(),
    );
  }
}

/// Uma empresa gestora / administrador indicado pelo afiliado.
class ClienteIndicado {
  final int id;
  final String nome;
  final String tipoCliente;
  final String? provincia;
  final String? municipio;
  final String? origem; // link | manual
  final String subscricaoEstado;
  final int numImoveis;
  final int nPagamentos;
  final double baseKz;
  final double comissaoKz;
  final DateTime? atribuidoEm;
  final DateTime? ultimoPagamentoEm;

  const ClienteIndicado({
    required this.id,
    required this.nome,
    required this.tipoCliente,
    required this.provincia,
    required this.municipio,
    required this.origem,
    required this.subscricaoEstado,
    required this.numImoveis,
    required this.nPagamentos,
    required this.baseKz,
    required this.comissaoKz,
    required this.atribuidoEm,
    required this.ultimoPagamentoEm,
  });

  String get localizacao => [municipio, provincia].where((e) => (e ?? '').isNotEmpty).join(', ');

  String get tipoLabel =>
      tipoCliente == 'admin_independente' ? 'Administrador independente' : 'Empresa gestora';

  factory ClienteIndicado.fromJson(Map<String, dynamic> j) => ClienteIndicado(
        id: _int(j['id']),
        nome: (j['nome'] ?? '').toString(),
        tipoCliente: (j['tipo_cliente'] ?? '').toString(),
        provincia: j['provincia']?.toString(),
        municipio: j['municipio']?.toString(),
        origem: j['origem']?.toString(),
        subscricaoEstado: (j['subscricao_estado'] ?? 'sem_subscricao').toString(),
        numImoveis: _int(j['num_imoveis']),
        nPagamentos: _int(j['n_pagamentos']),
        baseKz: _num(j['base_kz']),
        comissaoKz: _num(j['comissao_kz']),
        atribuidoEm: _data(j['atribuido_em']),
        ultimoPagamentoEm: _data(j['ultimo_pagamento_em']),
      );
}

/// Uma comissão — uma linha por pagamento do cliente.
class Comissao {
  final int id;
  final String? empresaNome;
  final String origemLabel;
  final String? origemNumero;
  final String descricao;
  final double valorPagoTotalKz;
  final double valorImpostoKz;
  final double valorBaseKz;
  final double taxaPct;
  final double valorComissaoKz;
  final String estado; // pendente | aprovada | paga | anulada
  final String estadoLabel;
  final DateTime? pagoPeloClienteEm;
  final String? disponivelEm;
  final String? pagamentoNumero;

  const Comissao({
    required this.id,
    required this.empresaNome,
    required this.origemLabel,
    required this.origemNumero,
    required this.descricao,
    required this.valorPagoTotalKz,
    required this.valorImpostoKz,
    required this.valorBaseKz,
    required this.taxaPct,
    required this.valorComissaoKz,
    required this.estado,
    required this.estadoLabel,
    required this.pagoPeloClienteEm,
    required this.disponivelEm,
    required this.pagamentoNumero,
  });

  factory Comissao.fromJson(Map<String, dynamic> j) => Comissao(
        id: _int(j['id']),
        empresaNome: (j['empresa'] as Map?)?['nome']?.toString(),
        origemLabel: (j['origem_label'] ?? '').toString(),
        origemNumero: j['origem_numero']?.toString(),
        descricao: (j['descricao'] ?? '').toString(),
        valorPagoTotalKz: _num(j['valor_pago_total_kz']),
        valorImpostoKz: _num(j['valor_imposto_kz']),
        valorBaseKz: _num(j['valor_base_kz']),
        taxaPct: _num(j['taxa_pct']),
        valorComissaoKz: _num(j['valor_comissao_kz']),
        estado: (j['estado'] ?? '').toString(),
        estadoLabel: (j['estado_label'] ?? '').toString(),
        pagoPeloClienteEm: _data(j['pago_pelo_cliente_em']),
        disponivelEm: j['disponivel_em']?.toString(),
        pagamentoNumero: (j['pagamento'] as Map?)?['numero']?.toString(),
      );
}

/// Uma página de comissões (o endpoint pagina de 25 em 25).
class PaginaComissoes {
  final List<Comissao> itens;
  final int pagina;
  final int ultimaPagina;
  final int total;
  final double totalComissaoKz;
  final double pendenteKz;
  final double aprovadaKz;
  final double pagaKz;

  const PaginaComissoes({
    required this.itens,
    required this.pagina,
    required this.ultimaPagina,
    required this.total,
    required this.totalComissaoKz,
    required this.pendenteKz,
    required this.aprovadaKz,
    required this.pagaKz,
  });

  bool get temMais => pagina < ultimaPagina;

  factory PaginaComissoes.fromJson(Map<String, dynamic> j) {
    final p = (j['comissoes'] as Map?)?.cast<String, dynamic>() ?? const {};
    final totais = (j['totais'] as Map?)?.cast<String, dynamic>() ?? const {};
    double porEstado(String e) =>
        _num((totais[e] as Map?)?['total_kz']);
    return PaginaComissoes(
      itens: ((p['data'] as List?) ?? [])
          .map((e) => Comissao.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      pagina: _int(p['current_page']),
      ultimaPagina: _int(p['last_page']),
      total: _int(p['total']),
      // O total que interessa é o do FILTRO aplicado, não o do painel: com o
      // filtro «Pagas» a soma em baixo tem de ser só a das pagas.
      totalComissaoKz: _num(totais['total_nao_anulada_kz']),
      pendenteKz: porEstado('pendente'),
      aprovadaKz: porEstado('aprovada'),
      pagaKz: porEstado('paga'),
    );
  }
}

/// Um pagamento recebido pelo afiliado (agrupa comissões aprovadas).
class PagamentoAfiliado {
  final int id;
  final String numero;
  final int numComissoes;
  final double valorBrutoKz;
  final double retencaoPct;
  final double retencaoValorKz;
  final double valorLiquidoKz;
  final String metodoLabel;
  final String? referenciaBancaria;
  final String? ibanDestino;
  final String? pagoEm;
  final String? notas;

  const PagamentoAfiliado({
    required this.id,
    required this.numero,
    required this.numComissoes,
    required this.valorBrutoKz,
    required this.retencaoPct,
    required this.retencaoValorKz,
    required this.valorLiquidoKz,
    required this.metodoLabel,
    required this.referenciaBancaria,
    required this.ibanDestino,
    required this.pagoEm,
    required this.notas,
  });

  factory PagamentoAfiliado.fromJson(Map<String, dynamic> j) => PagamentoAfiliado(
        id: _int(j['id']),
        numero: (j['numero'] ?? '').toString(),
        numComissoes: _int(j['num_comissoes']),
        valorBrutoKz: _num(j['valor_bruto_kz']),
        retencaoPct: _num(j['retencao_pct']),
        retencaoValorKz: _num(j['retencao_valor_kz']),
        valorLiquidoKz: _num(j['valor_liquido_kz']),
        metodoLabel: (j['metodo_label'] ?? j['metodo'] ?? '').toString(),
        referenciaBancaria: j['referencia_bancaria']?.toString(),
        ibanDestino: j['iban_destino']?.toString(),
        pagoEm: j['pago_em']?.toString(),
        notas: j['notas']?.toString(),
      );
}
