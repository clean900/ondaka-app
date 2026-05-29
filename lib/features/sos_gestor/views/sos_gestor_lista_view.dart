import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../sos/models/tipo_sos.dart';
import '../repositories/sos_gestor_repository.dart';
import 'sos_gestor_detalhe_view.dart';

class SosGestorListaView extends StatefulWidget {
  const SosGestorListaView({super.key});

  @override
  State<SosGestorListaView> createState() => _SosGestorListaViewState();
}

class _SosGestorListaViewState extends State<SosGestorListaView> {
  final _repo = SosGestorRepository();
  List<AlertaListado> _alertas = [];
  bool _isLoading = true;
  String? _erro;
  int _segundosDesdeUpdate = 0;

  late final Stream<int> _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);
  late final Stream<int> _polling = Stream.periodic(const Duration(seconds: 30), (i) => i);

  @override
  void initState() {
    super.initState();
    _carregar();
    _polling.listen((_) => _carregar());
    _ticker.listen((_) {
      if (mounted) setState(() => _segundosDesdeUpdate++);
    });
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    try {
      final lista = await _repo.meusAlertas();
      if (!mounted) return;
      setState(() {
        _alertas = lista;
        _isLoading = false;
        _erro = null;
        _segundosDesdeUpdate = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final abertos = _alertas.where((a) => a.estado == 'aberto').length;
    final criticos = _alertas.where((a) => a.estado == 'aberto' && a.gravidade == 'critico').length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Emergências SOS'),
        backgroundColor: AppColors.bgDark,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Há ${_segundosDesdeUpdate}s', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? _erroState()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(child: _stat('Em curso', '$abertos', AppColors.warning)),
                            const SizedBox(width: 10),
                            Expanded(child: _stat('Críticos', '$criticos', AppColors.danger, destaque: criticos > 0)),
                          ],
                        ),
                      ),
                      Expanded(child: _alertas.isEmpty ? _vazioState() : _lista()),
                    ],
                  ),
      ),
    );
  }

  Widget _stat(String label, String value, Color cor, {bool destaque = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: destaque ? 0.6 : 0.3), width: destaque ? 1.5 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: cor, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _lista() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _alertas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _Item(
        alerta: _alertas[i],
        onTap: () async {
          await Get.to(() => SosGestorDetalheView(alertaId: _alertas[i].id));
          _carregar();
        },
      ),
    );
  }

  Widget _erroState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
        const SizedBox(height: 16),
        Text(_erro ?? '', style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: _carregar, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
      ]));

  Widget _vazioState() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
          SizedBox(height: 16),
          Text('Sem alertas. Tudo calmo.', style: TextStyle(color: AppColors.textMain, fontSize: 14)),
        ]),
      );
}

class _Item extends StatelessWidget {
  final AlertaListado alerta;
  final VoidCallback onTap;
  const _Item({required this.alerta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final corG = switch (alerta.gravidade) {
      'critico' => AppColors.danger,
      'alto' => const Color(0xFFEA580C),
      'medio' => AppColors.warning,
      'baixo' => AppColors.success,
      _ => AppColors.cyan,
    };
    final corE = switch (alerta.estado) {
      'aberto' => AppColors.warning,
      'atendido' => AppColors.cyan,
      'resolvido' => AppColors.success,
      'falso_alarme' => AppColors.textMuted,
      _ => AppColors.textMuted,
    };
    final isAberto = alerta.estado == 'aberto';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: corG.withValues(alpha: isAberto ? 0.45 : 0.15), width: isAberto ? 1.0 : 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: corG.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.emergency_outlined, color: corG, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(alerta.tipoLabel, style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: corG.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(5)), child: Text(alerta.gravidade.toUpperCase(), style: TextStyle(color: corG, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4))),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: corE.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(5)), child: Text(alerta.estado.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: corE, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4))),
                    const SizedBox(width: 8),
                    if (alerta.createdAt != null)
                      Expanded(child: Text(DateFormat('dd/MM HH:mm').format(alerta.createdAt!.toLocal()), style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ]),
                  if (alerta.localizacao != null && alerta.localizacao!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Expanded(child: Text(alerta.localizacao!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
