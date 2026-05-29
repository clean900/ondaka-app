import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/marketplace_controller.dart';
import '../models/anuncio.dart';
import 'anuncio_detalhe_view.dart';
import 'criar_anuncio_view.dart';

class MeusAnunciosView extends StatelessWidget {
  const MeusAnunciosView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MeusAnunciosController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Os meus anúncios'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.anuncios.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (c.anuncios.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppColors.textFaint),
                  SizedBox(height: 12),
                  Text('Ainda não publicou anúncios',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.cyan,
          backgroundColor: AppColors.surface,
          onRefresh: c.carregar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: c.anuncios.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _MeuAnuncioCard(anuncio: c.anuncios[i], controller: c),
          ),
        );
      }),
    );
  }
}

class _MeuAnuncioCard extends StatelessWidget {
  final Anuncio anuncio;
  final MeusAnunciosController controller;
  const _MeuAnuncioCard({required this.anuncio, required this.controller});

  String _preco() {
    if (anuncio.preco == null) return 'A combinar';
    final s = anuncio.preco!.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$s Kz';
  }

  @override
  Widget build(BuildContext context) {
    final removido = anuncio.estadoModeracao == 'removido';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: removido ? AppColors.danger : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Get.to(() => AnuncioDetalheView(anuncioId: anuncio.id)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(anuncio.titulo,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                      const SizedBox(height: 2),
                      Text(_preco(), style: const TextStyle(fontSize: 14, color: AppColors.cyan)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textFaint),
              ],
            ),
          ),
          if (removido) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Removido pela moderação',
                  style: TextStyle(fontSize: 11, color: AppColors.dangerSoft)),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Estado: ', style: TextStyle(fontSize: 12, color: AppColors.textFaint)),
              Expanded(
                child: Text(anuncio.estadoVendaLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
                tooltip: 'Editar',
                onPressed: () async {
                  final r = await Get.to(() => CriarAnuncioView(anuncioEditar: anuncio));
                  if (r == true) controller.carregar();
                },
              ),
              _MenuEstado(
                actual: anuncio.estadoVenda,
                onSelect: (novo) => controller.alterarEstado(anuncio, novo),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuEstado extends StatelessWidget {
  final String actual;
  final void Function(String) onSelect;
  const _MenuEstado({required this.actual, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const opcoes = {
      'disponivel': 'Disponível',
      'em_negociacao': 'Em negociação',
      'vendido': 'Vendido',
      'cancelado': 'Cancelado',
    };

    return PopupMenuButton<String>(
      color: AppColors.surfaceHi,
      icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
      onSelected: onSelect,
      itemBuilder: (context) => opcoes.entries
          .where((e) => e.key != actual)
          .map((e) => PopupMenuItem<String>(
                value: e.key,
                child: Text(e.value, style: const TextStyle(color: AppColors.textMain)),
              ))
          .toList(),
    );
  }
}
