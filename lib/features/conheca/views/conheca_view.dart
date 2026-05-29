import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/catalogo_controller.dart';
import '../models/catalogo_feature.dart';

/// View "Conheça a ONDAKA" — catálogo completo das 86 funcionalidades.
///
/// Acessível a partir da tab "Mais".
class ConhecaView extends StatelessWidget {
  const ConhecaView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CatalogoController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Conheça a ONDAKA'),
        backgroundColor: AppColors.bgDark,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.categorias.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erro.value != null && controller.categorias.isEmpty) {
          return _erroState(controller);
        }

        if (controller.categorias.isEmpty) {
          return const Center(
            child: Text(
              'Catálogo não disponível.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.carregar(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _Header(controller: controller),
                    const SizedBox(height: 16),
                    _Busca(controller: controller),
                    const SizedBox(height: 12),
                    _FiltroEstado(controller: controller),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),

              // Lista de categorias filtradas
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: Obx(() {
                  final cats = controller.filtradas;

                  if (cats.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Nenhuma funcionalidade encontrada.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CategoriaCard(categoria: cats[index]),
                      childCount: cats.length,
                    ),
                  );
                }),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      }),
    );
  }

  Widget _erroState(CatalogoController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              c.erro.value ?? 'Erro ao carregar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => c.carregar(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER COM STATS
// ============================================================================
class _Header extends StatelessWidget {
  final CatalogoController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Tudo o que ',
              style: TextStyle(color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.w600),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.pink],
              ).createShader(bounds),
              child: const Text(
                'ONDAKA',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const Text(' faz', style: TextStyle(color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${stats['total']} funcionalidades em ${controller.categorias.length} áreas',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatPill(label: 'Em produção', valor: stats['pronto'] ?? 0, cor: AppColors.success),
            const SizedBox(width: 8),
            _StatPill(label: 'Em breve', valor: stats['breve'] ?? 0, cor: AppColors.cyan),
            const SizedBox(width: 8),
            _StatPill(label: 'Roadmap', valor: stats['roadmap'] ?? 0, cor: AppColors.purple),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int valor;
  final Color cor;
  const _StatPill({required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cor.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          children: [
            Text('$valor', style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BUSCA
// ============================================================================
class _Busca extends StatelessWidget {
  final CatalogoController controller;
  const _Busca({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (v) => controller.busca.value = v,
      style: const TextStyle(color: AppColors.textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Pesquisar funcionalidade...',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.surface.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5), width: 1),
        ),
      ),
    );
  }
}

// ============================================================================
// FILTRO ESTADO (chips)
// ============================================================================
class _FiltroEstado extends StatelessWidget {
  final CatalogoController controller;
  const _FiltroEstado({required this.controller});

  static const _opcoes = [
    {'value': 'todos', 'label': 'Todas'},
    {'value': 'pronto', 'label': 'Em produção'},
    {'value': 'breve', 'label': 'Em breve'},
    {'value': 'roadmap', 'label': 'Roadmap'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        final actual = controller.filtroEstado.value;
        return Row(
          children: _opcoes.map((op) {
            final selected = actual == op['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.filtroEstado.value = op['value']!,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.cyan.withValues(alpha: 0.15) : AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.cyan.withValues(alpha: 0.5) : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    op['label']!,
                    style: TextStyle(
                      color: selected ? AppColors.cyan : AppColors.textMain,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}

// ============================================================================
// CATEGORIA (expansão tile)
// ============================================================================
class _CategoriaCard extends StatelessWidget {
  final CatalogoCategoria categoria;
  const _CategoriaCard({required this.categoria});

  @override
  Widget build(BuildContext context) {
    final cor = _corDa(categoria.cor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: AppColors.textMuted,
          colorScheme: ColorScheme.fromSeed(seedColor: cor, brightness: Brightness.dark),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconeDa(categoria.iconName), color: cor, size: 20),
          ),
          title: Text(
            categoria.titulo,
            style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${categoria.features.length} ${categoria.features.length == 1 ? 'feature' : 'features'}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          iconColor: cor,
          collapsedIconColor: AppColors.textMuted,
          children: categoria.features.map((f) => _FeatureItem(feature: f, cor: cor)).toList(),
        ),
      ),
    );
  }

  static Color _corDa(String key) {
    switch (key) {
      case 'blue':
        return AppColors.cyan;
      case 'purple':
        return AppColors.purple;
      case 'pink':
        return AppColors.pink;
      case 'cyan':
      default:
        return AppColors.cyan;
    }
  }

  static IconData _iconeDa(String name) {
    switch (name) {
      case 'dollar-sign':
        return Icons.attach_money;
      case 'building':
        return Icons.business_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'users':
        return Icons.people_outline;
      case 'smartphone':
        return Icons.smartphone_outlined;
      case 'door-open':
        return Icons.door_front_door_outlined;
      case 'bot':
        return Icons.smart_toy_outlined;
      case 'plug':
        return Icons.electrical_services;
      case 'shield':
        return Icons.shield_outlined;
      case 'briefcase':
        return Icons.work_outline;
      default:
        return Icons.auto_awesome;
    }
  }
}

// ============================================================================
// FEATURE ITEM
// ============================================================================
class _FeatureItem extends StatelessWidget {
  final CatalogoFeature feature;
  final Color cor;

  const _FeatureItem({required this.feature, required this.cor});

  @override
  Widget build(BuildContext context) {
    final cfg = _estadoConfig(feature.estado);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        feature.nome,
                        style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (cfg['cor'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cfg['label'] as String,
                        style: TextStyle(color: cfg['cor'] as Color, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  feature.desc,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                ),
                if (feature.quando != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    feature.quando!,
                    style: TextStyle(color: cfg['cor'] as Color, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Object> _estadoConfig(String estado) {
    switch (estado) {
      case 'pronto':
        return {'label': 'Em produção', 'cor': AppColors.success};
      case 'curso':
        return {'label': 'Em curso', 'cor': AppColors.warning};
      case 'breve':
        return {'label': 'Em breve', 'cor': AppColors.cyan};
      case 'roadmap':
      default:
        return {'label': 'Roadmap', 'cor': AppColors.purple};
    }
  }
}
