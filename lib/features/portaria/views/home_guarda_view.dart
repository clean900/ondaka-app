import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pre_aprovacoes/views/historico_visitas_view.dart';
import '../repositories/portaria_repository.dart';
import 'portaria_encomendas_shell_view.dart';
import 'verificar_visitante_view.dart';
import '../../chamadas/views/ligar_condomino_view.dart';
import '../../sos_guarda/views/sos_guarda_lista_view.dart';
import '../../sos_guarda/repositories/sos_guarda_repository.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';

/// Home do guarda (funcionário de portaria).
///
/// Acesso às operações principais:
/// - Validar OTP introduzido pelo visitante
/// - Ver quem está dentro agora
///
/// Futuramente: scan de QR, entrada manual, histórico.
class HomeGuardaView extends StatelessWidget {
  const HomeGuardaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Portaria'),
        backgroundColor: AppColors.bgDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: StorageService.to.getUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Boas-vindas
                Text(
                  'Olá, ${user['name'] ?? 'Guarda'}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Portaria — ONDAKA',
                  style: TextStyle(
                    color: AppColors.cyanSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // === Card SOS (PRIORIDADE MÁXIMA) ===
                _SosGuardaCard(),
                const SizedBox(height: 14),

                // Botão principal — validar OTP
                _accaoGrande(
                  icon: Icons.password,
                  label: 'Validar código',
                  subtitle: 'Visitante apresentou OTP de 6 dígitos',
                  onTap: () => Get.toNamed(AppRoutes.validarOtp),
                  primary: true,
                ),
                const SizedBox(height: 14),

                // Encomendas
                _accaoGrande(
                  icon: Icons.inventory_2_outlined,
                  label: 'Encomendas',
                  subtitle: 'Gerir entregas e levantamentos',
                  onTap: () => Get.to(() => const PortariaEncomendasShellView()),
                  primary: false,
                ),
                const SizedBox(height: 14),

                // Botão secundário — dentro agora
                _accaoGrande(
                  icon: Icons.group,
                  label: 'Quem está dentro',
                  subtitle: 'Ver visitantes actualmente no condomínio',
                  onTap: () => Get.toNamed(AppRoutes.dentroAgora),
                  primary: false,
                ),
                const SizedBox(height: 14),
                _accaoGrande(
                  icon: Icons.history,
                  label: 'Histórico de visitas',
                  subtitle: 'Ver todas as visitas registadas',
                  onTap: () => Get.to(() => HistoricoVisitasView(
                        fetch: PortariaRepository().historicoVisitas,
                        tituloAppBar: 'Histórico do condomínio',
                      )),
                  primary: false,
                ),
                const SizedBox(height: 14),
                _accaoGrande(
                  icon: Icons.gpp_maybe_outlined,
                  label: 'Verificar visitante',
                  subtitle: 'Consultar a Lista Negra por BI, matrícula ou nome',
                  onTap: () => Get.to(() => const VerificarVisitanteView()),
                  primary: false,
                ),
                const SizedBox(height: 14),
                _accaoGrande(
                  icon: Icons.call,
                  label: 'Ligar ao morador',
                  subtitle: 'Chamada de voz para o morador de um imóvel',
                  onTap: () => Get.to(() => const LigarCondominoView()),
                  primary: false,
                ),
                const SizedBox(height: 32),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.06),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.cyanSoft, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Em construção',
                            style: TextStyle(
                              color: AppColors.cyanSoft,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Scanner de QR será adicionado em próximas iterações.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _accaoGrande({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: primary ? AppColors.brandGradient : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.25),
                    blurRadius: 25,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary
                    ? Colors.black.withValues(alpha: 0.15)
                    : AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primary ? const Color(0xFF001218) : AppColors.cyan,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: primary ? const Color(0xFF001218) : Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primary
                          ? Colors.black.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: primary ? const Color(0xFF001218) : AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'Terminar sessão',
      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      middleText: 'Tens a certeza que queres sair?',
      middleTextStyle:
          const TextStyle(color: AppColors.textMuted, fontSize: 13),
      backgroundColor: AppColors.surface,
      radius: 14,
      textCancel: 'Cancelar',
      textConfirm: 'Sair',
      confirmTextColor: AppColors.bgDark,
      buttonColor: AppColors.cyan,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirm == true) {
      await AuthService.to.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}

// ============================================================================
// CARD SOS — destaca alertas em curso para o guarda
// ============================================================================
class _SosGuardaCard extends StatefulWidget {
  @override
  State<_SosGuardaCard> createState() => _SosGuardaCardState();
}

class _SosGuardaCardState extends State<_SosGuardaCard> {
  final _repo = SosGuardaRepository();
  int _abertos = 0;
  int _criticos = 0;
  bool _carregado = false;
  late final Stream<int> _polling = Stream.periodic(const Duration(seconds: 30), (i) => i);

  @override
  void initState() {
    super.initState();
    _carregar();
    _polling.listen((_) => _carregar());
  }

  Future<void> _carregar() async {
    try {
      final lista = await _repo.meusAlertas();
      if (!mounted) return;
      setState(() {
        _abertos = lista.where((a) => a.estado == 'aberto').length;
        _criticos = lista.where((a) => a.estado == 'aberto' && a.gravidade == 'critico').length;
        _carregado = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAlertas = _abertos > 0;
    final hasCriticos = _criticos > 0;
    final cor = hasCriticos ? AppColors.danger : (hasAlertas ? AppColors.warning : AppColors.success);

    return InkWell(
      onTap: () async {
        await Get.to(() => const SosGuardaListaView());
        _carregar();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: hasAlertas
              ? LinearGradient(
                  colors: [cor.withValues(alpha: 0.25), cor.withValues(alpha: 0.10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasAlertas ? null : AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withValues(alpha: hasAlertas ? 0.5 : 0.2), width: 1.2),
          boxShadow: hasCriticos
              ? [BoxShadow(color: cor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasAlertas ? Icons.warning_amber : Icons.shield_outlined,
                color: cor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergências SOS',
                    style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !_carregado
                        ? 'A carregar…'
                        : hasCriticos
                            ? '$_criticos crítico${_criticos > 1 ? "s" : ""} em curso · TOQUE PARA AGIR'
                            : hasAlertas
                                ? '$_abertos alerta${_abertos > 1 ? "s" : ""} em curso'
                                : 'Nenhum alerta. Tudo calmo.',
                    style: TextStyle(
                      color: hasAlertas ? cor : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: hasCriticos ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (hasAlertas)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_abertos',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

