import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/prestadores_controller.dart';
import '../widgets/prestador_card.dart';
import 'prestador_detalhe_view.dart';

class PrestadoresView extends StatelessWidget {
  const PrestadoresView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(PrestadoresController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.prestadores.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          );
        }

        if (!c.addonActivo.value) {
          return const _AddonBloqueado();
        }

        if (c.erro.value != null && c.prestadores.isEmpty) {
          return _Erro(mensagem: c.erro.value!, onRetry: c.carregar);
        }

        return RefreshIndicator(
          color: AppColors.cyan,
          backgroundColor: AppColors.surface,
          onRefresh: c.refrescar,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Cabecalho()),
              SliverToBoxAdapter(child: _Categorias(c: c)),
              if (c.prestadores.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Vazio(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = c.prestadores[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PrestadorCard(
                            prestador: p,
                            onTap: () => Get.to(
                              () => PrestadorDetalheView(prestadorId: p.id),
                            ),
                          ),
                        );
                      },
                      childCount: c.prestadores.length,
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.brandGradient.createShader(b),
            child: const Text(
              'Encontre profissionais',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Canalizadores, electricistas, jardineiros e mais perto de si',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Categorias extends StatelessWidget {
  final PrestadoresController c;
  const _Categorias({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.categorias.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: c.categorias.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final cat = c.categorias[i];
            final activa = c.categoriaSeleccionada.value == cat.id;
            return GestureDetector(
              onTap: () => c.seleccionarCategoria(cat.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activa ? AppColors.cyan : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activa ? AppColors.cyan : AppColors.border,
                  ),
                ),
                child: Text(
                  cat.nome,
                  style: TextStyle(
                    fontSize: 13,
                    color: activa ? const Color(0xFF001218) : AppColors.textMuted,
                    fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
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
            Icon(Icons.store_outlined, size: 48, color: AppColors.textFaint),
            SizedBox(height: 12),
            Text(
              'Ainda não há prestadores nesta categoria',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
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
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}


class _AddonBloqueado extends StatelessWidget {
  const _AddonBloqueado();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_outline, size: 32, color: AppColors.textFaint),
            ),
            const SizedBox(height: 16),
            const Text(
              'Funcionalidade nao disponivel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A administracao do seu condominio ainda nao activou o directorio de prestadores de servico. Fale com a gestao para o disponibilizar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
