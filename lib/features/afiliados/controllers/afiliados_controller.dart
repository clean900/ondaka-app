import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../models/afiliado_models.dart';
import '../repositories/afiliados_repository.dart';

/// Controller do Programa de Afiliados na app.
///
/// CADA SEPARADOR CARREGA SOZINHO, à primeira vez que é aberto: o painel é o
/// que interessa a quem entra, e pedir quatro endpoints de uma vez numa rede
/// móvel angolana é fazer esperar por coisas que ninguém pediu.
class AfiliadosController extends GetxController {
  final _repo = AfiliadosRepository();

  // --- painel ---
  final painel = Rxn<PainelAfiliado>();
  final aCarregarPainel = false.obs;
  final erroPainel = RxnString();

  // --- clientes ---
  final clientes = <ClienteIndicado>[].obs;
  final aCarregarClientes = false.obs;
  final erroClientes = RxnString();
  bool _clientesPedidos = false;

  // --- comissões ---
  final comissoes = <Comissao>[].obs;
  final aCarregarComissoes = false.obs;
  final aCarregarMais = false.obs;
  final erroComissoes = RxnString();
  final filtroEstado = RxnString();
  final totaisComissoes = Rxn<PaginaComissoes>();
  bool _comissoesPedidas = false;

  // --- pagamentos ---
  final pagamentos = <PagamentoAfiliado>[].obs;
  final aCarregarPagamentos = false.obs;
  final erroPagamentos = RxnString();
  bool _pagamentosPedidos = false;

  Afiliado? get afiliado => painel.value?.afiliado;
  ResumoAfiliado? get resumo => painel.value?.resumo;
  MateriaisAfiliado? get materiais => painel.value?.materiais;

  @override
  void onInit() {
    super.onInit();
    carregarPainel();
  }

  Future<void> carregarPainel() async {
    aCarregarPainel.value = true;
    erroPainel.value = null;
    try {
      painel.value = await _repo.painel();
    } catch (_) {
      erroPainel.value = 'Não foi possível carregar o painel de afiliado.';
    } finally {
      aCarregarPainel.value = false;
    }
  }

  Future<void> carregarClientes({bool forcar = false}) async {
    if (_clientesPedidos && !forcar) return;
    _clientesPedidos = true;
    aCarregarClientes.value = true;
    erroClientes.value = null;
    try {
      clientes.assignAll(await _repo.clientes());
    } catch (_) {
      erroClientes.value = 'Não foi possível carregar os clientes indicados.';
    } finally {
      aCarregarClientes.value = false;
    }
  }

  Future<void> carregarComissoes({bool forcar = false}) async {
    if (_comissoesPedidas && !forcar) return;
    _comissoesPedidas = true;
    aCarregarComissoes.value = true;
    erroComissoes.value = null;
    try {
      final p = await _repo.comissoes(pagina: 1, estado: filtroEstado.value);
      totaisComissoes.value = p;
      comissoes.assignAll(p.itens);
    } catch (_) {
      erroComissoes.value = 'Não foi possível carregar as comissões.';
    } finally {
      aCarregarComissoes.value = false;
    }
  }

  /// Página seguinte — o endpoint devolve 25 de cada vez.
  Future<void> maisComissoes() async {
    final actual = totaisComissoes.value;
    if (actual == null || !actual.temMais || aCarregarMais.value) return;
    aCarregarMais.value = true;
    try {
      final p = await _repo.comissoes(pagina: actual.pagina + 1, estado: filtroEstado.value);
      totaisComissoes.value = p;
      comissoes.addAll(p.itens);
    } catch (_) {
      // Silencioso: a lista que já está no ecrã continua válida.
    } finally {
      aCarregarMais.value = false;
    }
  }

  void mudarFiltro(String? estado) {
    if (filtroEstado.value == estado) return;
    filtroEstado.value = estado;
    carregarComissoes(forcar: true);
  }

  Future<void> carregarPagamentos({bool forcar = false}) async {
    if (_pagamentosPedidos && !forcar) return;
    _pagamentosPedidos = true;
    aCarregarPagamentos.value = true;
    erroPagamentos.value = null;
    try {
      pagamentos.assignAll(await _repo.pagamentos());
    } catch (_) {
      erroPagamentos.value = 'Não foi possível carregar os pagamentos.';
    } finally {
      aCarregarPagamentos.value = false;
    }
  }

  /// Recarrega o separador visível (o gesto de puxar para actualizar).
  Future<void> recarregar(int separador) async {
    switch (separador) {
      case 1:
        await carregarClientes(forcar: true);
        break;
      case 2:
        await carregarComissoes(forcar: true);
        break;
      case 3:
        await carregarPagamentos(forcar: true);
        break;
      default:
        await carregarPainel();
    }
  }

  // ---------------------------------------------------------------
  // Partilha
  // ---------------------------------------------------------------

  void copiar(String texto, String oQue) {
    Clipboard.setData(ClipboardData(text: texto));
    Get.snackbar('Copiado', '$oQue copiado para a área de transferência',
        snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
  }

  /// Abre a folha de partilha do telefone — o WhatsApp aparece lá, e com ela
  /// o afiliado escolhe o contacto sem a app ter de pedir nada ao sistema.
  Future<void> partilhar(String texto, {String? assunto}) async {
    await Share.share(texto, subject: assunto);
  }
}
