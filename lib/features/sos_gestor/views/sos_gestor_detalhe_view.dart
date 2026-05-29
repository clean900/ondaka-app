import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../sos/models/tipo_sos.dart';
import '../repositories/sos_gestor_repository.dart';

/// Detalhe de um SOS para o guarda — com acções Atender/Resolver/Falso alarme.
class SosGestorDetalheView extends StatefulWidget {
  final int alertaId;
  const SosGestorDetalheView({super.key, required this.alertaId});

  @override
  State<SosGestorDetalheView> createState() => _SosGestorDetalheViewState();
}

class _SosGestorDetalheViewState extends State<SosGestorDetalheView> {
  final _repo = SosGestorRepository();
  final _notasController = TextEditingController();

  AlertaDetalhado? _alerta;
  bool _isLoading = true;
  bool _acaoEmCurso = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      final a = await _repo.obterDetalhe(widget.alertaId);
      if (!mounted) return;
      setState(() {
        _alerta = a;
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

  Future<void> _executarAcao(String acao, String labelSucesso) async {
    if (_acaoEmCurso) return;
    setState(() => _acaoEmCurso = true);

    try {
      await _repo.atualizarEstado(
        widget.alertaId,
        acao,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );
      if (!mounted) return;
      Get.snackbar(
        'Sucesso',
        labelSucesso,
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
        colorText: Colors.white,
      );
      _notasController.clear();
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Erro',
        'Não foi possível executar a acção.',
        backgroundColor: AppColors.danger.withValues(alpha: 0.2),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _acaoEmCurso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(_alerta != null ? 'Alerta #${_alerta!.id}' : 'Detalhe'),
        backgroundColor: AppColors.bgDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? _erroState()
              : _alerta != null
                  ? _conteudo(_alerta!)
                  : const Center(child: Text('Não encontrado', style: TextStyle(color: AppColors.textMuted))),
    );
  }

  Widget _erroState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  Widget _conteudo(AlertaDetalhado a) {
    final corG = _corGravidade(a.gravidade);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // === Card principal ===
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: corG.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: corG.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: corG.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.emergency_outlined, color: corG, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.gravidade.toUpperCase(),
                          style: TextStyle(color: corG, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.tipoLabel,
                          style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _badgeEstado(a.estado),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // === Acções (só se aberto ou atendido) ===
        if (a.estado == 'aberto' || a.estado == 'atendido') _accoes(a),
        if (a.estado == 'resolvido' || a.estado == 'falso_alarme') _resolvidoInfo(a),

        const SizedBox(height: 20),

        // === Info detalhada ===
        _campoInfo(Icons.business_outlined, 'Condomínio', a.condominioId.toString()),
        if (a.localizacao != null && a.localizacao!.isNotEmpty)
          _campoInfo(Icons.location_on_outlined, 'Localização', a.localizacao!),
        if (a.descricao != null && a.descricao!.isNotEmpty)
          _campoInfo(Icons.description_outlined, 'Descrição', a.descricao!),

        const SizedBox(height: 10),
        const Text('Cronologia', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _timeline(a),

        if (a.fotos.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Fotos anexadas', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: a.fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _verFotoCompleta(a.fotos[i].url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    a.fotos[i].url,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 110,
                      height: 110,
                      color: AppColors.surface,
                      child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),
      ],
    );
  }

  Widget _accoes(AlertaDetalhado a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ações', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _notasController,
          maxLines: 2,
          maxLength: 1000,
          style: const TextStyle(color: AppColors.textMain, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Notas sobre a resolução (opcional)',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        if (a.estado == 'aberto')
          _botaoAccao(
            icone: Icons.directions_run,
            label: 'A caminho / Atender',
            cor: AppColors.warning,
            onTap: () => _executarAcao('atender', 'Marcado como atendido.'),
          ),
        if (a.estado == 'aberto') const SizedBox(height: 8),
        _botaoAccao(
          icone: Icons.check_circle_outline,
          label: 'Resolver',
          cor: AppColors.success,
          onTap: () => _executarAcao('resolver', 'Alerta resolvido.'),
        ),
        const SizedBox(height: 8),
        _botaoAccao(
          icone: Icons.do_not_disturb_outlined,
          label: 'Falso alarme',
          cor: AppColors.textMuted,
          outlined: true,
          onTap: () => _executarAcao('falso_alarme', 'Marcado como falso alarme.'),
        ),
      ],
    );
  }

  Widget _botaoAccao({
    required IconData icone,
    required String label,
    required Color cor,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: _acaoEmCurso ? null : onTap,
              icon: Icon(icone, color: cor, size: 18),
              label: Text(label, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cor.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: _acaoEmCurso ? null : onTap,
              icon: Icon(icone, color: Colors.white, size: 18),
              label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
    );
  }

  Widget _resolvidoInfo(AlertaDetalhado a) {
    final isFalso = a.estado == 'falso_alarme';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isFalso ? AppColors.textMuted : AppColors.success).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isFalso ? Icons.do_not_disturb : Icons.check_circle,
            color: isFalso ? AppColors.textMuted : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFalso ? 'Marcado como falso alarme.' : 'Alerta resolvido.',
              style: TextStyle(
                color: isFalso ? AppColors.textMuted : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoInfo(IconData icone, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(valor, style: const TextStyle(color: AppColors.textMain, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(AlertaDetalhado a) {
    final eventos = <Widget>[];
    if (a.createdAt != null) {
      eventos.add(_eventoTimeline(Icons.add_alert_outlined, 'Alerta enviado', _formatarData(a.createdAt!), AppColors.cyan));
    }
    if (a.atendidoEm != null) {
      eventos.add(_eventoTimeline(Icons.support_agent, 'Atendido', _formatarData(a.atendidoEm!), AppColors.warning));
    }
    if (a.resolvidoEm != null) {
      eventos.add(_eventoTimeline(Icons.check_circle_outline, 'Resolvido', _formatarData(a.resolvidoEm!), AppColors.success));
    }
    if (a.resolucaoNotas != null && a.resolucaoNotas!.isNotEmpty) {
      eventos.add(Padding(
        padding: const EdgeInsets.only(left: 30, top: 4, bottom: 8),
        child: Text('"${a.resolucaoNotas!}"', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: eventos);
  }

  Widget _eventoTimeline(IconData icone, String label, String quando, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(11)),
            child: Icon(icone, size: 13, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(quando, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeEstado(String estado) {
    final cor = switch (estado) {
      'aberto' => AppColors.warning,
      'atendido' => AppColors.cyan,
      'resolvido' => AppColors.success,
      'falso_alarme' => AppColors.textMuted,
      _ => AppColors.textMuted,
    };
    final label = switch (estado) {
      'aberto' => 'EM CURSO',
      'atendido' => 'ATENDIDO',
      'resolvido' => 'RESOLVIDO',
      'falso_alarme' => 'FALSO ALARME',
      _ => estado.toUpperCase(),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
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

  String _formatarData(DateTime d) {
    return DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
  }

  void _verFotoCompleta(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
