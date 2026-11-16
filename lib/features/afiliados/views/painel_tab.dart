import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/afiliados_controller.dart';
import '../models/afiliado_models.dart';
import '../widgets/afiliados_ui.dart';

/// Separador «Painel»: o estado da conta, o link para partilhar, os números,
/// o escalão e os textos prontos a enviar.
class PainelTab extends StatelessWidget {
  final AfiliadosController c;

  const PainelTab({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.aCarregarPainel.value && c.painel.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.erroPainel.value != null && c.painel.value == null) {
        return CaixaErro(mensagem: c.erroPainel.value!, onTentar: c.carregarPainel);
      }

      final af = c.afiliado;
      final r = c.resumo;
      if (af == null || r == null) {
        return const Vazio(
          icone: Icons.handshake_outlined,
          titulo: 'Ainda não é afiliado',
          texto: 'O Programa de Afiliados da ONDAKA paga 6% a 10% de tudo o que cada cliente '
              'que indicar pagar à ONDAKA.\n\nA candidatura faz-se em ondaka.ao/afiliados — '
              'assim que for aprovada, o painel aparece aqui.',
        );
      }

      return RefreshIndicator(
        onRefresh: c.carregarPainel,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (!af.activo) _AvisoEstado(af: af),
            if (af.activo && !af.dadosPagamentoCompletos) const _AvisoIban(),

            _Identidade(af: af),
            const SizedBox(height: 14),

            _Link(c: c, af: af),
            const SizedBox(height: 14),

            // Os números, dois a dois — num telefone, seis cartões em linha
            // ficavam ilegíveis.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                CartaoKpi(
                  rotulo: 'Cliques no link',
                  valor: '${r.cliques}',
                  nota: '1 por visitante/dia',
                  icone: Icons.ads_click,
                  cor: AppColors.textFaint,
                ),
                CartaoKpi(
                  rotulo: 'Clientes indicados',
                  valor: '${r.registos}',
                  nota: '${r.registosMes} este mês',
                  icone: Icons.apartment_outlined,
                  cor: AppColors.cyan,
                ),
                CartaoKpi(
                  rotulo: 'Volume (12 meses)',
                  valor: kz(r.volume12mKz),
                  nota: 'define o seu escalão',
                  icone: Icons.trending_up,
                  cor: AppColors.purple,
                ),
                CartaoKpi(
                  rotulo: 'Em carência',
                  valor: kz(r.pendenteKz),
                  nota: '${r.pendenteN} comissão(ões) · ${r.carenciaDias} dias',
                  icone: Icons.schedule,
                  cor: AppColors.warning,
                ),
                CartaoKpi(
                  rotulo: 'Aprovado (a pagar)',
                  valor: kz(r.aprovadaKz),
                  nota: r.atingeMinimo
                      ? 'Atinge o mínimo de pagamento'
                      : 'Mínimo: ${kz(r.pagamentoMinimoKz)}',
                  icone: Icons.check_circle_outline,
                  cor: AppColors.success,
                ),
                CartaoKpi(
                  rotulo: 'Já pago',
                  valor: kz(r.pagaKz),
                  nota: r.ultimoPagamentoEm != null
                      ? 'Último: ${data(r.ultimoPagamentoEm)}'
                      : 'Sem pagamentos ainda',
                  icone: Icons.account_balance_wallet_outlined,
                  cor: AppColors.successSoft,
                ),
              ],
            ),
            const SizedBox(height: 14),

            _Escalao(c: c, af: af, r: r),
            const SizedBox(height: 14),

            if (r.serie12m.isNotEmpty) ...[
              Seccao(
                titulo: 'Comissões dos últimos 12 meses',
                icone: Icons.bar_chart,
                filho: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Este mês: ${kz(r.mesActualKz, cent: true)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    BarrasMensais(
                      meses: r.serie12m.map((m) => (label: m.label, valor: m.totalKz)).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (c.materiais != null) _Materiais(c: c, m: c.materiais!),
          ],
        ),
      );
    });
  }
}

class _Identidade extends StatelessWidget {
  final Afiliado af;
  const _Identidade({required this.af});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(af.nome,
                  style: const TextStyle(
                      color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Código ${af.codigo} · ${af.estadoLabel}',
                  style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(pct(af.taxaActualPct),
              style: const TextStyle(
                  color: AppColors.purpleSoft, fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _AvisoEstado extends StatelessWidget {
  final Afiliado af;
  const _AvisoEstado({required this.af});

  @override
  Widget build(BuildContext context) {
    final (cor, titulo, texto) = switch (af.estado) {
      'pendente' => (
          AppColors.warning,
          'Candidatura em análise',
          'O seu link só começa a atribuir clientes depois da aprovação. Avisamos por email.'
        ),
      'suspenso' => (
          AppColors.danger,
          'Conta suspensa',
          af.motivoSuspensao ?? 'Enquanto suspensa, o link não atribui clientes nem gera comissões.'
        ),
      'recusado' => (
          AppColors.danger,
          'Candidatura não aprovada',
          af.motivoRecusa ?? 'Contacte a ONDAKA para mais informações.'
        ),
      _ => (AppColors.info, af.estadoLabel, ''),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.w700)),
                if (texto.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(texto,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoIban extends StatelessWidget {
  const _AvisoIban();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_balance_outlined, color: AppColors.cyanSoft, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Falta o IBAN. Sem dados bancários não há transferência — preencha-os em '
              'ondaka.ao/afiliado/dados.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final AfiliadosController c;
  final Afiliado af;
  const _Link({required this.c, required this.af});

  @override
  Widget build(BuildContext context) {
    return Seccao(
      titulo: 'O seu link de indicação',
      icone: Icons.link,
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              af.link,
              style: const TextStyle(
                  color: AppColors.cyanSoft, fontSize: 12.5, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => c.copiar(af.link, 'Link'),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => c.partilhar(c.materiais?.whatsapp ?? af.link),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Partilhar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Quem abrir o link fica ligado a si durante 90 dias. Em alternativa, o cliente '
            'pode escrever o código ${af.codigo} no registo.',
            style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Escalao extends StatelessWidget {
  final AfiliadosController c;
  final Afiliado af;
  final ResumoAfiliado r;
  const _Escalao({required this.c, required this.af, required this.r});

  @override
  Widget build(BuildContext context) {
    final prox = r.proximoNivel;
    final escaloes = c.painel.value?.escaloes ?? const <Escalao>[];

    return Seccao(
      titulo: 'Escalão e taxa de comissão',
      icone: Icons.stairs_outlined,
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (af.taxaManual)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Taxa definida pela ONDAKA para esta conta.',
                  style: TextStyle(color: AppColors.purpleSoft, fontSize: 11.5)),
            ),
          if (prox != null) ...[
            Text('Faltam ${kz(prox.faltamKz)} de volume para ${pct(prox.taxaPct)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: prox.progresso(r.volume12mKz),
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
              ),
            ),
            const SizedBox(height: 6),
            Text('${kz(r.volume12mKz)} de ${kz(prox.minVolumeKz)} · volume dos últimos 12 meses',
                style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
          ] else
            Text('Está no escalão mais alto: ${pct(af.taxaActualPct)} sobre o valor sem imposto.',
                style: const TextStyle(color: AppColors.successSoft, fontSize: 12.5)),
          if (escaloes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            ...escaloes.map((e) {
              final actual = e.codigo == af.nivel;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.label,
                          style: TextStyle(
                            color: actual ? AppColors.textMain : AppColors.textMuted,
                            fontSize: 12.5,
                            fontWeight: actual ? FontWeight.w700 : FontWeight.w400,
                          )),
                    ),
                    Text(pct(e.taxaPct),
                        style: TextStyle(
                          color: actual ? AppColors.cyan : AppColors.textFaint,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            const Text(
              'A comissão incide sobre o valor SEM imposto de todos os pagamentos dos seus '
              'clientes — subscrição, add-ons e pacotes de SMS.',
              style: TextStyle(color: AppColors.textFaint, fontSize: 11.5, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _Materiais extends StatelessWidget {
  final AfiliadosController c;
  final MateriaisAfiliado m;
  const _Materiais({required this.c, required this.m});

  @override
  Widget build(BuildContext context) {
    return Seccao(
      titulo: 'Mensagens prontas a enviar',
      icone: Icons.campaign_outlined,
      filho: Column(
        children: [
          _Mensagem(
            titulo: 'WhatsApp',
            icone: Icons.chat_outlined,
            texto: m.whatsapp,
            onCopiar: () => c.copiar(m.whatsapp, 'Mensagem'),
            onPartilhar: () => c.partilhar(m.whatsapp),
          ),
          const SizedBox(height: 12),
          _Mensagem(
            titulo: 'Email',
            icone: Icons.mail_outline,
            texto: m.emailCorpo,
            onCopiar: () => c.copiar(m.emailCorpo, 'Texto do email'),
            onPartilhar: () => c.partilhar(m.emailCorpo, assunto: m.emailAssunto),
          ),
          const SizedBox(height: 12),
          _Mensagem(
            titulo: 'SMS',
            icone: Icons.sms_outlined,
            texto: m.sms,
            onCopiar: () => c.copiar(m.sms, 'SMS'),
            onPartilhar: () => c.partilhar(m.sms),
          ),
        ],
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final String texto;
  final VoidCallback onCopiar;
  final VoidCallback onPartilhar;

  const _Mensagem({
    required this.titulo,
    required this.icone,
    required this.texto,
    required this.onCopiar,
    required this.onPartilhar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 15, color: AppColors.cyanSoft),
              const SizedBox(width: 7),
              Text(titulo,
                  style: const TextStyle(
                      color: AppColors.textMain, fontSize: 12.5, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: onCopiar,
                icon: const Icon(Icons.copy, size: 16),
                color: AppColors.textMuted,
                tooltip: 'Copiar',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onPartilhar,
                icon: const Icon(Icons.share, size: 16),
                color: AppColors.cyan,
                tooltip: 'Partilhar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}
