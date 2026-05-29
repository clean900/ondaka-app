import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../models/tipo_sos.dart';
import '../repositories/sos_repository.dart';
import 'sos_detalhe_view.dart';

/// Lista dos meus alertas SOS (histórico).
class SosHistoricoView extends StatefulWidget {
  const SosHistoricoView({super.key});

  @override
  State<SosHistoricoView> createState() => _SosHistoricoViewState();
}

class _SosHistoricoViewState extends State<SosHistoricoView> {
  final _repo = SosRepository();
  List<AlertaListado> _alertas = [];
  bool _isLoading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      final lista = await _repo.meusAlertas();
      if (!mounted) return;
      setState(() {
        _alertas = lista;
        _isLoading = false;
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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Meus alertas SOS'),
        backgroundColor: AppColors.bgDark,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? _erroState()
                : _alertas.isEmpty
                    ? _vazioState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _alertas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _Item(
                          alerta: _alertas[i],
                          onTap: () => Get.to(() => SosDetalheView(alertaId: _alertas[i].id)),
                        ),
                      ),
      ),
    );
  }

  Widget _erroState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
              const SizedBox(height: 16),
              Text(_erro ?? '', style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vazioState() {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
              SizedBox(height: 16),
              Text(
                'Ainda não enviaste nenhum alerta SOS.',
                style: TextStyle(color: AppColors.textMain, fontSize: 14),
              ),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Em emergência, usa o botão SOS no topo do ecrã.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final AlertaListado alerta;
  final VoidCallback onTap;

  const _Item({required this.alerta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final corG = _corGravidade(alerta.gravidade);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: corG.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: corG.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.emergency_outlined, color: corG, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.tipoLabel,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(alerta.estado, _corEstado(alerta.estado)),
                      const SizedBox(width: 8),
                      if (alerta.createdAt != null)
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM HH:mm').format(alerta.createdAt!.toLocal()),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textFaint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Color _corGravidade(String g) {
    return switch (g) {
      'critico' => AppColors.danger,
      'alto' => const Color(0xFFEA580C),
      'medio' => AppColors.warning,
      'baixo' => AppColors.success,
      _ => AppColors.cyan,
    };
  }

  Color _corEstado(String e) {
    return switch (e) {
      'aberto' => AppColors.warning,
      'atendido' => AppColors.cyan,
      'resolvido' => AppColors.success,
      'falso_alarme' => AppColors.textMuted,
      _ => AppColors.textMuted,
    };
  }
}
