import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../assembleias/views/minhas_assembleias_view.dart';
import '../../avisos/views/meus_avisos_view.dart';
import '../../tickets/views/meus_tickets_view.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_data.dart';

/// Dashboard novo (v2) — carrossel topo + 3 secções por categoria.
/// Equivalente ao mockup aprovado em 29 Abr 2026.
class DashboardV2Widget extends StatefulWidget {
  const DashboardV2Widget({super.key});

  @override
  State<DashboardV2Widget> createState() => _DashboardV2WidgetState();
}

class _DashboardV2WidgetState extends State<DashboardV2Widget> {
  late final PageController _pageController;
  final _carrosselIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Obx(() {
      if (controller.isLoading.value && controller.dashboard.value == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.erro.value != null && controller.dashboard.value == null) {
        return _erroState(controller);
      }

      final data = controller.dashboard.value;
      if (data == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Carrossel topo ===
          SizedBox(
            height: 170,
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => _carrosselIndex.value = i,
              children: [
                _CardQuotaAtraso(),
                _CardQuotaAnual(),
                _CardProximaReuniao(data: data),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Obx(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final ativo = i == _carrosselIndex.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: ativo ? 18 : 6,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: ativo
                          ? AppColors.cyan
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ),

          // === Secção Reuniões ===
          _seccaoHeader(
            'Reuniões',
            onTapVerTodos: () => Get.to(() => const MinhasAssembleiasView()),
          ),
          if (data.assembleiasProximas.isEmpty)
            _emptySectionCard('Sem reuniões agendadas.')
          else
            _CardReuniao(
              titulo: data.assembleiasProximas.first.titulo,
              data: data.assembleiasProximas.first.dataAgendada,
              modo: data.assembleiasProximas.first.modo,
              onTap: () => Get.to(() => const MinhasAssembleiasView()),
            ),

          // === Secção Avisos ===
          _seccaoHeader(
            'Avisos · ${data.avisosNaoLidos} não lidos',
            onTapVerTodos: () => Get.to(() => const MeusAvisosView()),
          ),
          _CardAvisoPlaceholder(
            onTap: () => Get.to(() => const MeusAvisosView()),
          ),

          // === Secção Tickets ===
          _seccaoHeader(
            'Tickets · ${data.ticketsAbertos} abertos',
            onTapVerTodos: () => Get.to(() => const MeusTicketsView()),
          ),
          _CardTicketPlaceholder(
            onTap: () => Get.to(() => const MeusTicketsView()),
          ),

          const SizedBox(height: 16),
        ],
      );
    });
  }

  Widget _seccaoHeader(String titulo, {required VoidCallback onTapVerTodos}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: onTapVerTodos,
            child: const Row(
              children: [
                Text(
                  'ver todos',
                  style: TextStyle(color: AppColors.cyan, fontSize: 11),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward, size: 12, color: AppColors.cyan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySectionCard(String texto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(texto,
          style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
    );
  }

  Widget _erroState(DashboardController c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 28),
          const SizedBox(height: 8),
          Text(
            c.erro.value!,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: c.carregar,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CARDS DO CARROSSEL (FAKE — placeholder até existir Extracto Individual)
// =============================================================================

class _CardQuotaAtraso extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _carrosselCardWrapper(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.danger.withValues(alpha: 0.18),
              AppColors.danger.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUOTA EM ATRASO',
              style: TextStyle(
                color: AppColors.dangerSoft,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '30.000 Kz',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '2 meses · venceu há 12 dias',
              style: TextStyle(
                color: AppColors.dangerSoft,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Pagar agora →',
                style: TextStyle(
                  color: Color(0xFF001218),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardQuotaAnual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _carrosselCardWrapper(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUOTA ANUAL 2026',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '120.000 Kz',
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'PAGO',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '75.000',
                      style: TextStyle(
                        color: AppColors.successSoft,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.62,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.cyan, AppColors.pink],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '62% pago · 4 meses por liquidar',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardProximaReuniao extends StatelessWidget {
  final DashboardData data;
  const _CardProximaReuniao({required this.data});

  @override
  Widget build(BuildContext context) {
    final tem = data.assembleiasProximas.isNotEmpty;
    final a = tem ? data.assembleiasProximas.first : null;
    return _carrosselCardWrapper(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.info.withValues(alpha: 0.18),
              AppColors.info.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRÓXIMA REUNIÃO',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tem ? a!.titulo : 'Sem reuniões agendadas',
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (tem) ...[
              const SizedBox(height: 6),
              Text(
                _fmtData(a!.dataAgendada, a.modo),
                style: const TextStyle(color: AppColors.info, fontSize: 11),
              ),
            ],
            const Spacer(),
            if (tem)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Ver detalhes →',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtData(DateTime dt, String modo) {
    const meses = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    final dia = dt.day.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final modoLabel = modo == 'virtual' ? 'Virtual' : 'Presencial';
    return '$dia ${meses[dt.month]} · $hora:$min · $modoLabel';
  }
}

Widget _carrosselCardWrapper({required Widget child}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: child,
  );
}

// =============================================================================
// CARDS DAS SECÇÕES
// =============================================================================

class _CardReuniao extends StatelessWidget {
  final String titulo;
  final DateTime data;
  final String modo;
  final VoidCallback onTap;

  const _CardReuniao({
    required this.titulo,
    required this.data,
    required this.modo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.info.withValues(alpha: 0.18),
              AppColors.info.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_fmt(data)} · ${modo == 'virtual' ? 'Virtual' : 'Presencial'}',
              style: const TextStyle(color: AppColors.info, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    const meses = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month]}';
  }
}

class _CardAvisoPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _CardAvisoPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppColors.warning, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Toca para ver os teus avisos',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Comunicados do condomínio',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTicketPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _CardTicketPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppColors.cyan, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Toca para ver os teus tickets',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Pedidos abertos com a administração',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
