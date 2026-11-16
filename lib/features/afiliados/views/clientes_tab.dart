import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/afiliados_controller.dart';
import '../models/afiliado_models.dart';
import '../widgets/afiliados_ui.dart';

/// Separador «Clientes»: as empresas gestoras e administradores indicados.
class ClientesTab extends StatelessWidget {
  final AfiliadosController c;

  const ClientesTab({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    c.carregarClientes();

    return Obx(() {
      if (c.aCarregarClientes.value && c.clientes.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.erroClientes.value != null && c.clientes.isEmpty) {
        return CaixaErro(
          mensagem: c.erroClientes.value!,
          onTentar: () => c.carregarClientes(forcar: true),
        );
      }
      if (c.clientes.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => c.carregarClientes(forcar: true),
          child: ListView(
            children: const [
              SizedBox(height: 60),
              Vazio(
                icone: Icons.apartment_outlined,
                titulo: 'Ainda sem clientes indicados',
                texto: 'Partilhe o seu link no separador «Painel». Quando uma empresa gestora '
                    'ou um administrador independente se registar por ele, aparece aqui — e '
                    'cada pagamento que fizer passa a gerar comissão.',
              ),
            ],
          ),
        );
      }

      final total = c.clientes.fold<double>(0, (a, e) => a + e.comissaoKz);

      return RefreshIndicator(
        onRefresh: () => c.carregarClientes(forcar: true),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: c.clientes.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${c.clientes.length} cliente(s) · ${kz(total)} de comissão gerada',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
              );
            }
            return _CartaoCliente(cliente: c.clientes[i - 1]);
          },
        ),
      );
    });
  }
}

class _CartaoCliente extends StatelessWidget {
  final ClienteIndicado cliente;
  const _CartaoCliente({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final activa = cliente.subscricaoEstado == 'activa';
    final corSub = switch (cliente.subscricaoEstado) {
      'activa' => AppColors.success,
      'trial' || 'grace' => AppColors.info,
      'em_atraso' || 'suspensa' => AppColors.warning,
      'cancelada' || 'arquivada' => AppColors.danger,
      _ => AppColors.textFaint,
    };
    final rotuloSub = switch (cliente.subscricaoEstado) {
      'activa' => 'Subscrição activa',
      'trial' => 'Em trial',
      'grace' => 'Fim do trial',
      'em_atraso' => 'Pagamento em atraso',
      'suspensa' => 'Suspensa',
      'cancelada' => 'Cancelada',
      'arquivada' => 'Arquivada',
      _ => 'Sem subscrição',
    };

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
                child: Text(cliente.nome,
                    style: const TextStyle(
                        color: AppColors.textMain, fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: corSub.withValues(alpha: 0.14),
                  border: Border.all(color: corSub.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(rotuloSub,
                    style: TextStyle(color: corSub, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            [
              cliente.tipoLabel,
              if (cliente.localizacao.isNotEmpty) cliente.localizacao,
            ].join(' · '),
            style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 6),
          LinhaDetalhe('Indicado em',
              '${dataDe(cliente.atribuidoEm)}${cliente.origem == 'link' ? ' · pelo seu link' : ' · atribuído pela ONDAKA'}'),
          LinhaDetalhe('Imóveis', cliente.numImoveis > 0 ? '${cliente.numImoveis}' : '—'),
          LinhaDetalhe('Pagamentos que já fez', '${cliente.nPagamentos}'),
          LinhaDetalhe('Base gerada (sem imposto)', kz(cliente.baseKz)),
          LinhaDetalhe(
            'Comissão sua',
            kz(cliente.comissaoKz, cent: true),
            corValor: cliente.comissaoKz > 0 ? AppColors.successSoft : AppColors.textFaint,
          ),
          if (cliente.ultimoPagamentoEm != null)
            LinhaDetalhe('Último pagamento', dataDe(cliente.ultimoPagamentoEm)),
          if (!activa && cliente.nPagamentos == 0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Enquanto não tiver subscrição paga, não gera comissão.',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}
