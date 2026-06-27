import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/models/visita.dart';
import '../../../shared/models/visita_item.dart';
import '../repositories/portaria_repository.dart';

enum ModoItens { entrada, saida }

/// Ecrã do add-on Controlo de Bens.
///
/// - Modo ENTRADA: o guarda regista os itens que o visitante traz.
/// - Modo SAÍDA: o guarda reconcilia cada item (saiu/ficou) e fecha a saída.
///   Só os itens registados na entrada podem sair.
class ItensVisitaView extends StatefulWidget {
  final Visita visita;
  final ModoItens modo;

  const ItensVisitaView({super.key, required this.visita, required this.modo});

  @override
  State<ItensVisitaView> createState() => _ItensVisitaViewState();
}

class _ItensVisitaViewState extends State<ItensVisitaView> {
  final _repo = PortariaRepository();

  List<VisitaItem> _itens = [];
  bool _carregando = true;
  bool _addonInativo = false;
  String? _erro;
  bool _aProcessar = false;

  bool get _ehSaida => widget.modo == ModoItens.saida;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final itens = await _repo.listarItens(widget.visita.id);
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _carregando = false;
      });
    } on AddonInativoException catch (e) {
      if (!mounted) return;
      setState(() {
        _addonInativo = true;
        _carregando = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar os itens.';
      });
    }
  }

  int get _porResolver => _itens.where((i) => i.estaDentro).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text(_ehSaida ? 'Conferir itens à saída' : 'Itens à entrada'),
      ),
      floatingActionButton: (!_ehSaida && !_addonInativo && !_carregando)
          ? FloatingActionButton.extended(
              onPressed: _aProcessar ? null : _abrirFormAdicionar,
              backgroundColor: AppColors.cyan,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Adicionar item',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            )
          : null,
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : _addonInativo
              ? _addonInativoView()
              : _conteudo(),
    );
  }

  Widget _conteudo() {
    return Column(
      children: [
        _cabecalhoVisitante(),
        Expanded(
          child: _itens.isEmpty
              ? _vazioView()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _itens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _itemCard(_itens[i]),
                ),
        ),
        if (_ehSaida) _barraConfirmarSaida(),
      ],
    );
  }

  Widget _cabecalhoVisitante() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.visita.visitante?.nome ?? 'Visitante',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(widget.visita.fraccao?.label ?? 'Imóvel #${widget.visita.fraccaoId}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          if (_ehSaida && _itens.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _porResolver == 0
                  ? 'Todos os itens resolvidos.'
                  : '$_porResolver item(ns) por resolver — marque saiu ou ficou.',
              style: TextStyle(
                color: _porResolver == 0 ? AppColors.successSoft : AppColors.warningSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemCard(VisitaItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.quantidade > 1 ? '${item.quantidade}× ${item.descricao}' : item.descricao,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (item.identificador != null && item.identificador!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.identificador!,
                          style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              _estadoBadge(item),
              if (!_ehSaida && item.estaDentro)
                IconButton(
                  onPressed: _aProcessar ? null : () => _removerItem(item),
                  icon: const Icon(Icons.delete_outline, color: AppColors.dangerSoft, size: 20),
                  tooltip: 'Remover',
                ),
            ],
          ),
          if (_ehSaida && item.estaDentro) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _aProcessar ? null : () => _resolver(item, 'saiu'),
                    icon: const Icon(Icons.logout, size: 16, color: AppColors.successSoft),
                    label: const Text('Saiu', style: TextStyle(color: AppColors.successSoft)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.success)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _aProcessar ? null : () => _resolver(item, 'ficou'),
                    icon: const Icon(Icons.home_outlined, size: 16, color: AppColors.warningSoft),
                    label: const Text('Ficou', style: TextStyle(color: AppColors.warningSoft)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.warning)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoBadge(VisitaItem item) {
    final cor = switch (item.estado) {
      'saiu' => AppColors.success,
      'ficou' => AppColors.warning,
      _ => AppColors.cyan,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(item.estadoLabel, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _barraConfirmarSaida() {
    final podeFechar = _porResolver == 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (!podeFechar || _aProcessar) ? null : _confirmarSaida,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _aProcessar
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(podeFechar ? 'CONFIRMAR SAÍDA' : 'RESOLVA OS ITENS PRIMEIRO',
                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _vazioView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white.withValues(alpha: 0.2), size: 56),
            const SizedBox(height: 14),
            Text(
              _ehSaida ? 'Sem itens registados nesta visita.' : 'Ainda sem itens.\nUse "Adicionar item" para registar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addonInativoView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.purpleSoft, size: 48),
            const SizedBox(height: 14),
            Text(_erro ?? 'Esta funcionalidade requer o add-on Controlo de Bens.',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Get.back(), child: const Text('Voltar')),
          ],
        ),
      ),
    );
  }

  // === Acções ===

  Future<void> _resolver(VisitaItem item, String resolucao) async {
    setState(() => _aProcessar = true);
    try {
      final atualizado = await _repo.resolverItem(widget.visita.id, item.id, resolucao: resolucao);
      if (!mounted) return;
      setState(() {
        final idx = _itens.indexWhere((i) => i.id == item.id);
        if (idx != -1) _itens[idx] = atualizado;
      });
    } catch (e) {
      _snack('Não foi possível resolver o item.');
    } finally {
      if (mounted) setState(() => _aProcessar = false);
    }
  }

  Future<void> _removerItem(VisitaItem item) async {
    setState(() => _aProcessar = true);
    try {
      await _repo.removerItem(widget.visita.id, item.id);
      if (!mounted) return;
      setState(() => _itens.removeWhere((i) => i.id == item.id));
    } catch (e) {
      _snack('Não foi possível remover o item.');
    } finally {
      if (mounted) setState(() => _aProcessar = false);
    }
  }

  Future<void> _confirmarSaida() async {
    setState(() => _aProcessar = true);
    try {
      await _repo.registarSaida(widget.visita.id);
      if (!mounted) return;
      Get.back(result: true);
      _snack('Saída registada.');
    } catch (e) {
      if (mounted) setState(() => _aProcessar = false);
      _snack('Não foi possível registar a saída.');
    }
  }

  void _abrirFormAdicionar() {
    final descricao = TextEditingController();
    final quantidade = TextEditingController(text: '1');
    final identificador = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Novo item', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _campo(descricao, 'Descrição', hint: 'Ex.: Computador portátil',
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Indique a descrição' : null),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: _campo(quantidade, 'Qtd.', keyboard: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(identificador, 'Nº série / marca (opcional)')),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Get.back();
                    await _adicionar(
                      descricao.text.trim(),
                      int.tryParse(quantidade.text.trim()) ?? 1,
                      identificador.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Registar item', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label,
      {String? hint, String? Function(String?)? validator, TextInputType? keyboard}) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textFaint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }

  Future<void> _adicionar(String descricao, int quantidade, String identificador) async {
    setState(() => _aProcessar = true);
    try {
      final item = await _repo.registarItem(
        widget.visita.id,
        descricao: descricao,
        quantidade: quantidade < 1 ? 1 : quantidade,
        identificador: identificador,
      );
      if (!mounted) return;
      setState(() => _itens.add(item));
    } catch (e) {
      _snack('Não foi possível registar o item.');
    } finally {
      if (mounted) setState(() => _aProcessar = false);
    }
  }

  void _snack(String msg) {
    Get.snackbar('Controlo de bens', msg, snackPosition: SnackPosition.BOTTOM);
  }
}
