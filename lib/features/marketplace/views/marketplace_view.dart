import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/marketplace_controller.dart';
import '../widgets/anuncio_card.dart';
import 'anuncio_detalhe_view.dart';
import 'criar_anuncio_view.dart';
import 'meus_anuncios_view.dart';
import 'subscrever_view.dart';

class MarketplaceView extends StatelessWidget {
  const MarketplaceView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MarketplaceController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'Os meus anúncios',
            onPressed: () => Get.to(() => const MeusAnunciosView()),
          ),
        ],
      ),
      floatingActionButton: Obx(() => !c.podePublicar.value
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Subscrever'),
              onPressed: () async {
                await Get.to(() => const SubscreverView());
                c.refrescar();
              },
            )
          : FloatingActionButton.extended(
              backgroundColor: AppColors.cyan,
              foregroundColor: const Color(0xFF001218),
              icon: const Icon(Icons.add),
              label: const Text('Publicar'),
              onPressed: () async {
                final criado = await Get.to(() => const CriarAnuncioView());
                if (criado == true) c.refrescar();
              },
            )),
      body: Obx(() {
        if (c.isLoading.value && c.anuncios.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (c.erro.value != null && c.anuncios.isEmpty) {
          return _Erro(mensagem: c.erro.value!, onRetry: c.carregar);
        }

        return RefreshIndicator(
          color: AppColors.cyan,
          backgroundColor: AppColors.surface,
          onRefresh: c.refrescar,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Cabecalho(podePublicar: c.podePublicar.value)),
              SliverToBoxAdapter(child: _Filtros(c: c)),
              if (c.anuncios.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _Vazio())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final a = c.anuncios[i];
                        return AnuncioCard(
                          anuncio: a,
                          onTap: () => Get.to(() => AnuncioDetalheView(anuncioId: a.id)),
                        );
                      },
                      childCount: c.anuncios.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final bool podePublicar;
  const _Cabecalho({required this.podePublicar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.brandGradient.createShader(b),
            child: const Text(
              'Compra e venda entre vizinhos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            podePublicar
                ? 'Produtos e serviços dos condóminos'
                : 'Veja anúncios. Para publicar, active a subscrição.',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  final MarketplaceController c;
  const _Filtros({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Chip(label: 'Produtos', activo: c.tipoSeleccionado.value == 'produto',
                  onTap: () => c.seleccionarTipo('produto')),
              const SizedBox(width: 8),
              _Chip(label: 'Serviços', activo: c.tipoSeleccionado.value == 'servico',
                  onTap: () => c.seleccionarTipo('servico')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: Obx(() => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: c.categorias.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = c.categorias[i];
                  return _Chip(
                    label: cat.nome,
                    activo: c.categoriaSeleccionada.value == cat.id,
                    onTap: () => c.seleccionarCategoria(cat.id),
                  );
                },
              )),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? AppColors.cyan : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? AppColors.cyan : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              color: activo ? const Color(0xFF001218) : AppColors.textMuted,
              fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: AppColors.textFaint),
            SizedBox(height: 12),
            Text('Ainda não há anúncios por aqui',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _Erro({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.dangerSoft),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
