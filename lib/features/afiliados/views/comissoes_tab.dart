import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/afiliados_controller.dart';
import '../models/afiliado_models.dart';
import '../widgets/afiliados_ui.dart';

/// Separador «Comissões»: uma linha por pagamento do cliente, com a conta
/// feita — o que ele pagou, o imposto, a base, a taxa e a comissão.
class ComissoesTab extends StatefulWidget {
  final AfiliadosController c;

  const ComissoesTab({super.key, required this.c});

  @override
  State<ComissoesTab> createState() => _ComissoesTabState();
}

class _ComissoesTabState extends State<ComissoesTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.c.carregarComissoes();
    // Página seguinte quando chega perto do fim — 25 de cada vez.
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 320) {
        widget.c.maisComissoes();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;

    return Obx(() {
      final filtro = c.filtroEstado.value;

      final filtros = Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(rotulo: 'Todas', activo: filtro == null, onTap: () => c.mudarFiltro(null)),
              _Chip(
                  rotulo: 'Em carência',
                  activo: filtro == 'pendente',
                  onTap: () => c.mudarFiltro('pendente')),
              _Chip(
                  rotulo: 'Aprovadas',
                  activo: filtro == 'aprovada',
                  onTap: () => c.mudarFiltro('aprovada')),
              _Chip(rotulo: 'Pagas', activo: filtro == 'paga', onTap: () => c.mudarFiltro('paga')),
              _Chip(
                  rotulo: 'Anuladas',
                  activo: filtro == 'anulada',
                  onTap: () => c.mudarFiltro('anulada')),
            ],
          ),
        ),
      );

      Widget corpo;
      if (c.aCarregarComissoes.value && c.comissoes.isEmpty) {
        corpo = const Center(child: CircularProgressIndicator());
      } else if (c.erroComissoes.value != null && c.comissoes.isEmpty) {
        corpo = CaixaErro(
          mensagem: c.erroComissoes.value!,
          onTentar: () => c.carregarComissoes(forcar: true),
        );
      } else if (c.comissoes.isEmpty) {
        corpo = RefreshIndicator(
          onRefresh: () => c.carregarComissoes(forcar: true),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              Vazio(
                icone: Icons.receipt_long_outlined,
                titulo: filtro == null ? 'Ainda sem comissões' : 'Nenhuma comissão neste estado',
                texto: filtro == null
                    ? 'Cada pagamento que um cliente seu fizer à ONDAKA — subscrição, add-ons '
                        'ou pacotes de SMS — gera aqui uma linha.'
                    : 'Experimente outro filtro.',
              ),
            ],
          ),
        );
      } else {
        final p = c.totaisComissoes.value;
        corpo = RefreshIndicator(
          onRefresh: () => c.carregarComissoes(forcar: true),
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: c.comissoes.length + 2,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${p?.total ?? c.comissoes.length} comissão(ões)'
                    '${p != null ? ' · ${kz(p.totalComissaoKz, cent: true)} (sem as anuladas)' : ''}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                );
              }
              if (i == c.comissoes.length + 1) {
                if (c.aCarregarMais.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return const SizedBox.shrink();
              }
              return _CartaoComissao(comissao: c.comissoes[i - 1]);
            },
          ),
        );
      }

      return Column(children: [filtros, Expanded(child: corpo)]);
    });
  }
}

class _Chip extends StatelessWidget {
  final String rotulo;
  final bool activo;
  final VoidCallback onTap;

  const _Chip({required this.rotulo, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: activo ? AppColors.cyan.withValues(alpha: 0.16) : AppColors.surface,
            border: Border.all(
                color: activo ? AppColors.cyan.withValues(alpha: 0.5) : AppColors.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            rotulo,
            style: TextStyle(
              color: activo ? AppColors.cyanSoft : AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoComissao extends StatelessWidget {
  final Comissao comissao;
  const _CartaoComissao({required this.comissao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comissao.empresaNome ?? 'Cliente',
                        style: const TextStyle(
                            color: AppColors.textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${comissao.origemLabel} · ${dataDe(comissao.pagoPeloClienteEm)}',
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              EstadoComissao(estado: comissao.estado, label: comissao.estadoLabel),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 6),
          LinhaDetalhe('O cliente pagou', kz(comissao.valorPagoTotalKz, cent: true)),
          LinhaDetalhe('Imposto incluído', '− ${kz(comissao.valorImpostoKz, cent: true)}',
              corValor: AppColors.textFaint),
          LinhaDetalhe('Base da comissão', kz(comissao.valorBaseKz, cent: true)),
          LinhaDetalhe('Taxa aplicada', pct(comissao.taxaPct)),
          LinhaDetalhe('A sua comissão', kz(comissao.valorComissaoKz, cent: true),
              corValor: AppColors.successSoft),
          if (comissao.estado == 'pendente' && comissao.disponivelEm != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Aprovada a partir de ${data(comissao.disponivelEm)}.',
                  style: const TextStyle(color: AppColors.warningSoft, fontSize: 11.5)),
            ),
          if (comissao.pagamentoNumero != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Paga no pagamento ${comissao.pagamentoNumero}.',
                  style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5)),
            ),
          if (comissao.origemNumero != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Documento ${comissao.origemNumero}',
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11, fontFamily: 'monospace')),
            ),
        ],
      ),
    );
  }
}
