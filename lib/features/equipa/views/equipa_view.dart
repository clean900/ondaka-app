import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/equipa_controller.dart';
import '../models/equipa_membro.dart';

/// Ecra da equipa do condominio.
/// Mostra users internos (admin/gestor/funcionarios/guardas) + empresas prestadoras.
class EquipaView extends StatelessWidget {
  const EquipaView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EquipaController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Equipa do Condominio'),
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.membros.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erro.value != null && controller.membros.isEmpty) {
          return _ErroState(
            mensagem: controller.erro.value!,
            onRetry: controller.carregar,
          );
        }

        if (controller.membros.isEmpty) {
          return const _VazioState();
        }

        return RefreshIndicator(
          color: AppColors.cyan,
          backgroundColor: AppColors.surface,
          onRefresh: controller.carregar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pessoas
              if (controller.users.isNotEmpty) ...[
                _SecaoHeader(
                  titulo: 'Pessoas',
                  total: controller.users.length,
                  icone: Icons.people_outline,
                ),
                const SizedBox(height: 8),
                ...controller.users.map((m) => _MembroCard(membro: m)),
                const SizedBox(height: 24),
              ],

              // Empresas
              if (controller.empresas.isNotEmpty) ...[
                _SecaoHeader(
                  titulo: 'Empresas Prestadoras',
                  total: controller.empresas.length,
                  icone: Icons.business_outlined,
                ),
                const SizedBox(height: 8),
                ...controller.empresas.map((m) => _MembroCard(membro: m)),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}

class _SecaoHeader extends StatelessWidget {
  final String titulo;
  final int total;
  final IconData icone;

  const _SecaoHeader({
    required this.titulo,
    required this.total,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 20, color: AppColors.cyan),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            total.toString(),
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembroCard extends StatelessWidget {
  final EquipaMembro membro;

  const _MembroCard({required this.membro});

  Future<void> _ligar() async {
    if (!membro.temTelefone) return;
    final tel = membro.telefone!.replaceAll(' ', '');
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'Erro',
        'Nao foi possivel iniciar a chamada.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Avatar circular com inicial + icone do role
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: membro.corRole.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: membro.corRole.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  membro.inicial,
                  style: TextStyle(
                    color: membro.corRole,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    membro.iconeRole,
                    size: 12,
                    color: membro.corRole,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Nome + cargo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membro.nome,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  membro.cargo,
                  style: TextStyle(
                    color: membro.corRole,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (membro.temTelefone) ...[
                  const SizedBox(height: 2),
                  Text(
                    membro.telefone!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botao ligar
          if (membro.temTelefone)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _ligar,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VazioState extends StatelessWidget {
  const _VazioState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.people_outline,
              color: AppColors.textFaint,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sem membros na equipa',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroState extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;

  const _ErroState({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMain, fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.cyan),
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
