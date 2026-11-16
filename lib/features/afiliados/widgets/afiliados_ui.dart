import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';

/// Peças de interface partilhadas pelos quatro separadores do Programa de
/// Afiliados. Vivem aqui para os separadores ficarem com o conteúdo e não com
/// a decoração repetida quatro vezes.

String kz(num v, {bool cent = false}) {
  final f = NumberFormat(cent ? '#,##0.00' : '#,##0', 'pt_PT');
  return '${f.format(v)} Kz';
}

String pct(num v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  return '$s%';
}

String data(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  return DateFormat('dd/MM/yyyy').format(d);
}

String dataDe(DateTime? d) => d == null ? '—' : DateFormat('dd/MM/yyyy').format(d);

/// Cartão de número: rótulo pequeno em cima, valor grande, nota por baixo.
class CartaoKpi extends StatelessWidget {
  final String rotulo;
  final String valor;
  final String? nota;
  final IconData icone;
  final Color cor;

  const CartaoKpi({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.cor,
    this.nota,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.06),
        border: Border.all(color: cor.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rotulo.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icone, size: 16, color: cor),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (nota != null) ...[
            const SizedBox(height: 4),
            Text(nota!, style: const TextStyle(color: AppColors.textFaint, fontSize: 11, height: 1.3)),
          ],
        ],
      ),
    );
  }
}

/// Caixa com título, para agrupar conteúdo.
class Seccao extends StatelessWidget {
  final String titulo;
  final IconData? icone;
  final Widget? accao;
  final Widget filho;

  const Seccao({super.key, required this.titulo, required this.filho, this.icone, this.accao});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              children: [
                if (icone != null) Icon(icone, size: 16, color: AppColors.cyanSoft),
                if (icone != null) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?accao,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(14), child: filho),
        ],
      ),
    );
  }
}

/// Etiqueta do estado de uma comissão.
class EstadoComissao extends StatelessWidget {
  final String estado;
  final String label;

  const EstadoComissao({super.key, required this.estado, required this.label});

  @override
  Widget build(BuildContext context) {
    final cor = switch (estado) {
      'paga' => AppColors.success,
      'aprovada' => AppColors.info,
      'pendente' => AppColors.warning,
      'anulada' => AppColors.danger,
      _ => AppColors.textFaint,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? estado : label,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Linha de detalhe: rótulo à esquerda, valor à direita.
class LinhaDetalhe extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color? corValor;
  final bool mono;

  const LinhaDetalhe(this.rotulo, this.valor, {super.key, this.corValor, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(rotulo, style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: corValor ?? AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vazio — nunca um painel em branco: diz o que falta acontecer.
class Vazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;

  const Vazio({super.key, required this.icone, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 42, color: AppColors.textFaint),
            const SizedBox(height: 14),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

/// Erro com botão de tentar outra vez.
class CaixaErro extends StatelessWidget {
  final String mensagem;
  final Future<void> Function() onTentar;

  const CaixaErro({super.key, required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.textFaint),
            const SizedBox(height: 14),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onTentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar outra vez'),
            ),
          ],
        ),
      ),
    );
  }
}

/// O gráfico dos últimos doze meses, em barras simples.
/// Sem biblioteca: são doze barras e uma régua — não vale um pacote novo.
class BarrasMensais extends StatelessWidget {
  final List<({String label, double valor})> meses;

  const BarrasMensais({super.key, required this.meses});

  @override
  Widget build(BuildContext context) {
    final maximo = meses.fold<double>(0, (a, m) => m.valor > a ? m.valor : a);
    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: meses.map((m) {
          final frac = maximo <= 0 ? 0.0 : m.valor / maximo;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (m.valor > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: FittedBox(
                        child: Text(
                          NumberFormat.compact(locale: 'pt_PT').format(m.valor),
                          style: const TextStyle(color: AppColors.cyanSoft, fontSize: 9),
                        ),
                      ),
                    ),
                  Container(
                    height: (6 + frac * 80).toDouble(),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: m.valor > 0
                            ? [AppColors.cyan, AppColors.purple]
                            : [AppColors.border, AppColors.border],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    child: Text(
                      m.label,
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
