import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../models/tipo_sos.dart';
import '../repositories/sos_repository.dart';

/// Detalhe de um alerta SOS (estado, atendimento, fotos).
class SosDetalheView extends StatefulWidget {
  final int alertaId;
  const SosDetalheView({super.key, required this.alertaId});

  @override
  State<SosDetalheView> createState() => _SosDetalheViewState();
}

class _SosDetalheViewState extends State<SosDetalheView> {
  final _repo = SosRepository();
  AlertaDetalhado? _alerta;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(_alerta != null ? 'Alerta #${_alerta!.id}' : 'Detalhe'),
        backgroundColor: AppColors.bgDark,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? _erroState()
                : _alerta != null
                    ? _conteudo(_alerta!)
                    : const Center(child: Text('Não encontrado', style: TextStyle(color: AppColors.textMuted))),
      ),
    );
  }

  Widget _erroState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
        const SizedBox(height: 16),
        Text(_erro ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }

  Widget _conteudo(AlertaDetalhado a) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Card principal (tipo + gravidade)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _gravidadeCor(a.gravidade).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gravidadeCor(a.gravidade).withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _gravidadeCor(a.gravidade).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.emergency_outlined, color: _gravidadeCor(a.gravidade), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.tipoLabel, style: TextStyle(color: _gravidadeCor(a.gravidade), fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _badgeEstado(a.estado),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Localização
        if (a.localizacao != null && a.localizacao!.isNotEmpty)
          _campoInfo(Icons.location_on_outlined, 'Localização', a.localizacao!),

        // Descrição
        if (a.descricao != null && a.descricao!.isNotEmpty)
          _campoInfo(Icons.description_outlined, 'Descrição', a.descricao!),

        // Timeline
        const SizedBox(height: 10),
        const Text('Cronologia', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _timeline(a),

        // Fotos
        if (a.fotos.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Fotos anexadas', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: a.fotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _verFotoCompleta(a.fotos[i].url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    a.fotos[i].url,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
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

  Widget _campoInfo(IconData icone, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(valor, style: const TextStyle(color: AppColors.textMain, fontSize: 14, height: 1.4)),
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
    final cfg = _estadoConfig(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (cfg['cor']! as Color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(cfg['label'] as String, style: TextStyle(color: cfg['cor'] as Color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Map<String, Object> _estadoConfig(String estado) {
    return switch (estado) {
      'aberto' => {'label': 'A aguardar', 'cor': AppColors.warning},
      'atendido' => {'label': 'Atendido', 'cor': AppColors.cyan},
      'resolvido' => {'label': 'Resolvido', 'cor': AppColors.success},
      'falso_alarme' => {'label': 'Falso alarme', 'cor': AppColors.textMuted},
      _ => {'label': estado, 'cor': AppColors.textMuted},
    };
  }

  Color _gravidadeCor(String g) {
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
