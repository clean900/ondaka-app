import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../controllers/afiliados_controller.dart';
import 'apresentacao_tab.dart';
import 'clientes_tab.dart';
import 'comissoes_tab.dart';
import 'painel_tab.dart';
import 'pagamentos_tab.dart';

/// Programa de Afiliados na app — os mesmos ecrãs do portal web: painel,
/// clientes indicados, comissões, pagamentos e a apresentação do programa.
///
/// SÓ LEITURA. A candidatura, a adesão e os dados bancários continuam na web:
/// têm termos a aceitar e um IBAN a conferir, e isso não se faz de passagem.
///
/// [eHome] quando este é o ecrã principal do utilizador — um afiliado sem
/// condomínio nem empresa não tem para onde voltar, por isso leva o botão de
/// sair no lugar da seta.
class AfiliadosView extends StatelessWidget {
  final bool eHome;

  const AfiliadosView({super.key, this.eHome = false});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AfiliadosController());

    return DefaultTabController(
      length: 5,
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            automaticallyImplyLeading: !eHome,
            title: const Text('Programa de Afiliados'),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: () => c.recarregar(DefaultTabController.of(context).index),
              ),
              if (eHome)
                IconButton(
                  tooltip: 'Sair',
                  icon: const Icon(Icons.logout),
                  onPressed: () => _confirmarSaida(context),
                ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.cyan,
              unselectedLabelColor: AppColors.textFaint,
              indicatorColor: AppColors.cyan,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(fontSize: 13),
              tabs: [
                Tab(text: 'Painel'),
                Tab(text: 'Clientes'),
                Tab(text: 'Comissões'),
                Tab(text: 'Pagamentos'),
                Tab(text: 'Apresentação'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              PainelTab(c: c),
              ClientesTab(c: c),
              ComissoesTab(c: c),
              PagamentosTab(c: c),
              ApresentacaoTab(c: c),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sair?', style: TextStyle(color: AppColors.textMain)),
        content: const Text('Tem a certeza que pretende terminar a sessão?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await AuthService.to.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
