import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/acordo_controller.dart';
import '../models/acordo.dart';

class AcordosView extends StatelessWidget {
  const AcordosView({super.key});

  String _kz(double v) => NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz ', decimalDigits: 2).format(v);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AcordoController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Acordo de pagamento'),
        backgroundColor: AppColors.bgDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Como funciona',
            onPressed: () => _mostrarRegras(context),
          ),
        ],
      ),
      body: Obx(() {
        if (c.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final acordo = c.acordoEmCurso;

        return RefreshIndicator(
          onRefresh: c.carregar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (acordo == null) _proporNovo(context, c),
              if (acordo != null) ..._verAcordo(context, c, acordo),
            ],
          ),
        );
      }),
    );
  }

  // ---------- ACORDO EXISTENTE (negociação ou ativo) ----------

  List<Widget> _verAcordo(BuildContext context, AcordoController c, Acordo a) {
    return [
      _cabecalhoEstado(a),
      const SizedBox(height: 16),
      if (a.propostas.isNotEmpty) _historico(a),
      if (a.aguardaCondomino) ...[
        const SizedBox(height: 16),
        _accoesCondomino(context, c, a),
      ],
      if (a.aguardaGestor)
        _aviso('A sua proposta foi enviada. Aguarda resposta da gestão.', AppColors.warning),
      if (a.estaAtivo) ...[
        const SizedBox(height: 16),
        _prestacoes(a),
      ],
    ];
  }

  void _mostrarRegras(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Acordo de Pagamento', style: TextStyle(color: AppColors.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _regraSeccao('O que é', ['Plano para pagar as Taxas em atraso de forma faseada, em vez de tudo de uma vez.']),
              _regraSeccao('Como funciona', [
                'Propõe o nº de prestações na app → a gestão aceita ou contrapõe → até 3 rondas de cada lado.',
                'Pode acrescer juro definido pelo condomínio, sempre mostrado antes de aceitar.',
              ]),
              _regraSeccao('Como cumprir', [
                'Pague ao ritmo combinado, pelos meios normais (referência, transferência, depósito, numerário).',
                'Cada prestação tem data + 10 dias de tolerância.',
                'Em dia com o plano → acesso restabelecido automaticamente.',
              ]),
              _regraSeccao('Atenção', [
                'O acordo resolve a dívida antiga. As taxas do mês continuam e pagam-se em 10 dias após o lançamento.',
              ]),
              _regraSeccao('Incumprimento', [
                'Prestação com +10 dias de atraso → acordo quebrado (renegociar).',
                'Taxa do mês não paga em 10 dias → acesso limitado, mesmo com acordo em dia.',
              ]),
              const SizedBox(height: 8),
              const Text('Mesmo limitado, pode sempre ver o extrato, pagar, acompanhar o acordo e contactar a gestão (SOS).',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: AppColors.bgDark),
                  child: const Text('Entendi'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _regraSeccao(String titulo, List<String> pontos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: AppColors.cyanSoft, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...pontos.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    Expanded(child: Text(p, style: const TextStyle(color: AppColors.textMain, fontSize: 13, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _cabecalhoEstado(Acordo a) {
    String label;
    Color cor;
    IconData icon;
    switch (a.estado) {
      case 'aguarda_condomino':
        label = 'A gestão enviou uma contraproposta';
        cor = AppColors.purple;
        icon = Icons.mark_chat_unread;
        break;
      case 'aguarda_gestor':
        label = 'A aguardar resposta da gestão';
        cor = AppColors.warning;
        icon = Icons.hourglass_top;
        break;
      case 'aprovado':
      case 'em_cumprimento':
        label = 'Acordo activo';
        cor = AppColors.success;
        icon = Icons.check_circle;
        break;
      default:
        label = a.estado;
        cor = AppColors.textMuted;
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: cor),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 16))),
          ]),
          const SizedBox(height: 8),
          Text('Dívida: ${_kz(a.valorTotal)}', style: const TextStyle(color: AppColors.textMuted)),
          if (a.valorComJuro > a.valorTotal)
            Text('Juro: ${_kz(a.valorComJuro - a.valorTotal)}', style: const TextStyle(color: AppColors.textMuted)),
          if (a.valorComJuro > 0)
            Text('Total a pagar: ${_kz(a.valorComJuro)}', style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600)),
          Text('Rondas usadas — você: ${a.rondasCondomino}/3 · gestão: ${a.rondasGestor}/3',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _historico(Acordo a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Histórico da negociação', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...a.propostas.map((p) => _bolhaProposta(p)),
      ],
    );
  }

  Widget _bolhaProposta(Proposta p) {
    final ehGestor = p.ehGestor;
    return Align(
      alignment: ehGestor ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: ehGestor ? AppColors.surface : AppColors.cyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ehGestor ? "Gestão" : "Você"} · ronda ${p.ronda}',
                style: TextStyle(color: ehGestor ? AppColors.purpleSoft : AppColors.cyanSoft, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${p.numPrestacoes} prestações · total ${_kz(p.valorComJuro)}',
                style: const TextStyle(color: AppColors.textMain)),
            if (p.valorEntrada > 0)
              Text('Entrada: ${_kz(p.valorEntrada)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            if (p.observacoes != null && p.observacoes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('"${p.observacoes}"', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _accoesCondomino(BuildContext context, AcordoController c, Acordo a) {
    final podeContrapropor = a.rondasCondomino < 3;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('A gestão propõe estes termos. O que pretende fazer?',
              style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Obx(() => ElevatedButton.icon(
                onPressed: c.aSubmeter.value ? null : () => c.aceitar(a.id),
                icon: const Icon(Icons.check),
                label: const Text('Aceitar proposta'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
              )),
          const SizedBox(height: 8),
          if (podeContrapropor)
            Obx(() => OutlinedButton.icon(
                  onPressed: c.aSubmeter.value ? null : () => _dialogoContrapropor(context, c, a),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Fazer contraproposta'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.cyan, side: const BorderSide(color: AppColors.cyan), padding: const EdgeInsets.symmetric(vertical: 13)),
                )),
          if (!podeContrapropor)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Já usou as suas 3 contrapropostas. Pode aceitar ou recusar.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          Obx(() => TextButton.icon(
                onPressed: c.aSubmeter.value ? null : () => c.recusar(a.id),
                icon: const Icon(Icons.close, color: AppColors.danger),
                label: const Text('Recusar e encerrar', style: TextStyle(color: AppColors.danger)),
              )),
        ],
      ),
    );
  }

  void _dialogoContrapropor(BuildContext context, AcordoController c, Acordo a) {
    final num = (a.numPrestacoes).obs;
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Contraproposta', style: TextStyle(color: AppColors.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Número de prestações:', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 10),
            Obx(() => Wrap(
                  spacing: 8,
                  children: [2, 3, 4, 5, 6].map((n) {
                    final sel = num.value == n;
                    return GestureDetector(
                      onTap: () => num.value = n,
                      child: Container(
                        width: 42, height: 42, alignment: Alignment.center,
                        decoration: BoxDecoration(color: sel ? AppColors.cyan : AppColors.surfaceHi, borderRadius: BorderRadius.circular(10)),
                        child: Text('$n', style: TextStyle(color: sel ? AppColors.bgDark : AppColors.textMain, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              c.contrapropor(a.id, num.value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: AppColors.bgDark),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Widget _prestacoes(Acordo a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prestações', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...a.prestacoes.map((p) {
            final paga = p.estado == 'paga';
            final atrasada = p.estado == 'atrasada';
            final cor = paga ? AppColors.success : (atrasada ? AppColors.danger : AppColors.textMuted);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Icon(paga ? Icons.check_circle : Icons.circle_outlined, size: 18, color: cor),
                const SizedBox(width: 10),
                Text('Prestação ${p.numero}', style: const TextStyle(color: AppColors.textMain)),
                const Spacer(),
                Text(_kz(p.valor), style: const TextStyle(color: AppColors.textMain)),
                const SizedBox(width: 10),
                Text(p.dataVencimentoFmt, style: TextStyle(color: cor, fontSize: 12)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _aviso(String texto, Color cor) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.info_outline, color: cor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: TextStyle(color: cor))),
      ]),
    );
  }

  // ---------- PROPOR NOVO (sem acordo) ----------

  Widget _proporNovo(BuildContext context, AcordoController c) {
    final num = 3.obs;
    final lim = c.limitacao.value;
    final total = lim?.totalEmDivida ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Propor um plano de pagamento', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Divida o valor em atraso em prestações. A gestão poderá aceitar ou fazer uma contraproposta.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4)),
          const SizedBox(height: 16),
          if (total > 0) Text('Valor em atraso: ${_kz(total)}', style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Text('Número de prestações', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Obx(() => Wrap(
                spacing: 8,
                children: [2, 3, 4, 5, 6].map((n) {
                  final sel = num.value == n;
                  return GestureDetector(
                    onTap: () => num.value = n,
                    child: Container(
                      width: 44, height: 44, alignment: Alignment.center,
                      decoration: BoxDecoration(color: sel ? AppColors.cyan : AppColors.surfaceHi, borderRadius: BorderRadius.circular(10)),
                      child: Text('$n', style: TextStyle(color: sel ? AppColors.bgDark : AppColors.textMain, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 12),
          if (total > 0)
            Obx(() => Text('≈ ${_kz(total / num.value)} por mês (antes de juros/entrada)',
                style: const TextStyle(color: AppColors.cyanSoft, fontSize: 12))),
          const SizedBox(height: 20),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: c.aSubmeter.value ? null : () => c.propor(num.value),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: AppColors.bgDark, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(c.aSubmeter.value ? 'A enviar...' : 'Propor acordo'),
                ),
              )),
        ],
      ),
    );
  }
}
