import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/prestadores_controller.dart';
import '../models/prestador.dart';

class PrestadorDetalheView extends StatelessWidget {
  final int prestadorId;
  const PrestadorDetalheView({super.key, required this.prestadorId});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(
      PrestadorDetalheController(prestadorId),
      tag: 'prestador_$prestadorId',
    );

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Prestador'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.prestador.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        final p = c.prestador.value;
        if (p == null) {
          return Center(
            child: Text(c.erro.value ?? 'Erro', style: const TextStyle(color: AppColors.textMuted)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(prestador: p),
            const SizedBox(height: 20),
            if (p.telefone != null) _Contacto(telefone: p.telefone!),
            const SizedBox(height: 20),
            _BotaoAvaliar(controller: c),
            const SizedBox(height: 20),
            const Text(
              'Avaliações',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMain),
            ),
            const SizedBox(height: 12),
            if (c.avaliacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Ainda sem avaliações. Seja o primeiro!',
                    style: TextStyle(color: AppColors.textFaint)),
              )
            else
              ...c.avaliacoes.map((a) => _AvaliacaoItem(avaliacao: a)),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final Prestador prestador;
  const _Header({required this.prestador});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: prestador.fotoUrl != null
              ? Image.network(
                  prestador.fotoUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _avatarInicial(prestador.nome),
                )
              : _avatarInicial(prestador.nome),
        ),
        const SizedBox(height: 12),
        Text(
          prestador.nome,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textMain),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 18, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              prestador.totalAvaliacoes > 0
                  ? '${prestador.mediaEstrelas} · ${prestador.totalAvaliacoes} avaliações'
                  : 'Sem avaliações',
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
        if (prestador.especialidades != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prestador.especialidades!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ],
    );
  }
}

Widget _avatarInicial(String nome) {
  return Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      gradient: AppColors.brandGradient,
      borderRadius: BorderRadius.circular(20),
    ),
    alignment: Alignment.center,
    child: Text(
      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
    ),
  );
}

class _Contacto extends StatelessWidget {
  final String telefone;
  const _Contacto({required this.telefone});

  Future<void> _ligar() async {
    final tel = telefone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$tel');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch retornou false');
    } catch (_) {
      Get.snackbar(
        'Sem aplicação de chamadas',
        'Este dispositivo não tem marcador. Número: $telefone',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textMain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _ligar,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text('Contactar prestador',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoAvaliar extends StatelessWidget {
  final PrestadorDetalheController controller;
  const _BotaoAvaliar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _abrirDialogo(context),
      icon: const Icon(Icons.star_outline, size: 18),
      label: const Text('Avaliar este prestador'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.cyan,
        side: const BorderSide(color: AppColors.cyan),
      ),
    );
  }

  void _abrirDialogo(BuildContext context) {
    final estrelas = 5.obs;
    final comentarioCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A sua avaliação',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textMain)),
              const SizedBox(height: 16),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final n = i + 1;
                      return IconButton(
                        onPressed: () => estrelas.value = n,
                        icon: Icon(
                          n <= estrelas.value ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 32,
                        ),
                      );
                    }),
                  )),
              const SizedBox(height: 12),
              TextField(
                controller: comentarioCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Comentário (opcional)',
                  hintStyle: const TextStyle(color: AppColors.textFaint),
                  filled: true,
                  fillColor: AppColors.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.aEnviar.value
                          ? null
                          : () async {
                              final ok = await controller.enviarAvaliacao(
                                estrelas.value,
                                comentarioCtrl.text.trim(),
                              );
                              if (ok) Get.back();
                            },
                      child: Text(controller.aEnviar.value ? 'A enviar...' : 'Enviar avaliação'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvaliacaoItem extends StatelessWidget {
  final AvaliacaoPrestador avaliacao;
  const _AvaliacaoItem({required this.avaliacao});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                avaliacao.autorNome ?? 'Condómino',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) => Icon(
                      i < avaliacao.estrelas ? Icons.star : Icons.star_border,
                      size: 14,
                      color: AppColors.warning,
                    )),
              ),
            ],
          ),
          if (avaliacao.comentario != null && avaliacao.comentario!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(avaliacao.comentario!,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
