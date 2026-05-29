import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../sos_gestor/repositories/sos_gestor_repository.dart';
import '../../sos_gestor/views/sos_gestor_lista_view.dart';

/// Home do gestor (admin-empresa, gestor, administrador-condominio).
///
/// Mostra:
/// - Saudação + nome do gestor
/// - Card SOS destacado (com badge de críticos)
/// - Outras acções de gestão (futuro: dashboard simples, condomínios, etc.)
class HomeGestorView extends StatelessWidget {
  const HomeGestorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Gestão'),
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
                Text(
                  'Olá, ${user['name'] ?? 'Gestor'}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gestão — ONDAKA',
                  style: TextStyle(
                    color: AppColors.cyanSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // === Card SOS (PRIORIDADE MÁXIMA) ===
                _SosGestorCard(),
                const SizedBox(height: 14),

                // === Info card ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.06),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.cyanSoft, size: 18),
                          SizedBox(width: 8),
                          Text('Em desenvolvimento',
                              style: TextStyle(
                                color: AppColors.cyanSoft,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              )),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mais acções de gestão mobile chegam em breve.\nA gestão completa está disponível na plataforma web.',
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

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sair?', style: TextStyle(color: AppColors.textMain)),
        content: const Text('Tem a certeza que pretende terminar a sessão?', style: TextStyle(color: AppColors.textMuted)),
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

// ============================================================================
// CARD SOS — destaca alertas em curso para o gestor
// ============================================================================
class _SosGestorCard extends StatefulWidget {
  @override
  State<_SosGestorCard> createState() => _SosGestorCardState();
}

class _SosGestorCardState extends State<_SosGestorCard> {
  final _repo = SosGestorRepository();
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
        await Get.to(() => const SosGestorListaView());
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
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
              child: Icon(hasAlertas ? Icons.warning_amber : Icons.shield_outlined, color: cor, size: 28),
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
                decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
                child: Text('$_abertos', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
