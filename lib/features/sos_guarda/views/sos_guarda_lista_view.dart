import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../sos/models/tipo_sos.dart';
import '../repositories/sos_guarda_repository.dart';
import '../utils/sos_sirene.dart';
import 'sos_guarda_detalhe_view.dart';

/// Lista de alertas SOS dos condomínios atribuídos ao guarda.
/// Faz polling 30s automático.
class SosGuardaListaView extends StatefulWidget {
  const SosGuardaListaView({super.key});

  @override
  State<SosGuardaListaView> createState() => _SosGuardaListaViewState();
}

class _SosGuardaListaViewState extends State<SosGuardaListaView> {
  final _repo = SosGuardaRepository();
  List<AlertaListado> _alertas = [];
  bool _isLoading = true;
  String? _erro;
  int _segundosDesdeUpdate = 0;
  Set<int> _idsAbertosVistos = {};
  bool _silenciado = false;

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
      _avaliarSirene(lista);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar.';
        _isLoading = false;
      });
    }
  }

  /// Toca a sirene quando há SOS abertos; volta a tocar se chegar um novo
  /// mesmo depois de silenciado; pára quando não há nenhum aberto.
  void _avaliarSirene(List<AlertaListado> lista) {
    final abertos = lista.where((a) => a.estado == 'aberto').map((a) => a.id).toSet();
    final novos = abertos.difference(_idsAbertosVistos);
    _idsAbertosVistos = abertos;

    if (abertos.isEmpty) {
      _silenciado = false;
      SosSirene.instance.parar();
      return;
    }
    if (novos.isNotEmpty) {
      _silenciado = false;
      SosSirene.instance.tocar();
    } else if (!_silenciado && !SosSirene.instance.aTocar) {
      SosSirene.instance.tocar();
    }
    if (mounted) setState(() {});
  }

  void _silenciar() {
    setState(() => _silenciado = true);
    SosSirene.instance.parar();
  }

  @override
  void dispose() {
    SosSirene.instance.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final abertosCount = _alertas.where((a) => a.estado == 'aberto').length;
    final criticosCount = _alertas.where((a) => a.estado == 'aberto' && a.gravidade == 'critico').length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Emergências SOS'),
        backgroundColor: AppColors.bgDark,
        actions: [
          if (SosSirene.instance.aTocar)
            IconButton(
              onPressed: _silenciar,
              tooltip: 'Silenciar sirene',
              icon: const Icon(Icons.volume_off, color: AppColors.danger),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Há ${_segundosDesdeUpdate}s',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
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
                      _statsBar(abertosCount, criticosCount),
                      Expanded(
                        child: _alertas.isEmpty ? _vazioState() : _listaAlertas(),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _statsBar(int abertos, int criticos) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _statCard('Em curso', '$abertos', AppColors.warning)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Críticos', '$criticos', AppColors.danger, destaque: criticos > 0)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color cor, {bool destaque = false}) {
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

  Widget _listaAlertas() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _alertas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _Item(
        alerta: _alertas[i],
        onTap: () async {
          await Get.to(() => SosGuardaDetalheView(alertaId: _alertas[i].id));
          _carregar(); // refresh ao voltar
        },
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
        SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
              SizedBox(height: 16),
              Text(
                'Sem alertas. Tudo calmo.',
                style: TextStyle(color: AppColors.textMain, fontSize: 14),
              ),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Será notificado quando chegar um SOS dos condomínios sob a sua vigilância.',
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
    final corE = _corEstado(alerta.estado);
    final isAberto = alerta.estado == 'aberto';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: corG.withValues(alpha: isAberto ? 0.45 : 0.15),
            width: isAberto ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: corG.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.emergency_outlined, color: corG, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alerta.tipoLabel,
                          style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _badge(alerta.gravidade.toUpperCase(), corG),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _badge(_estadoLabel(alerta.estado), corE),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alerta.createdAt != null ? DateFormat('dd/MM HH:mm').format(alerta.createdAt!.toLocal()) : '',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (alerta.localizacao != null && alerta.localizacao!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alerta.localizacao!,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
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

  String _estadoLabel(String e) {
    return switch (e) {
      'aberto' => 'EM CURSO',
      'atendido' => 'ATENDIDO',
      'resolvido' => 'RESOLVIDO',
      'falso_alarme' => 'FALSO ALARME',
      _ => e.toUpperCase(),
    };
  }
}
