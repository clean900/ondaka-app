import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/reservas_controller.dart';
import '../models/reserva_models.dart';

class PedirReservaView extends StatefulWidget {
  final ReservaEspaco espaco;
  const PedirReservaView({super.key, required this.espaco});

  @override
  State<PedirReservaView> createState() => _PedirReservaViewState();
}

class _PedirReservaViewState extends State<PedirReservaView> {
  DateTime? _data;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  final _motivoCtrl = TextEditingController();
  bool _aEnviar = false;
  List<Map<String, String>> _ocupadas = const [];
  bool _aCarregarOcupadas = false;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final esp = widget.espaco;
    final agora = DateTime.now();
    final minima = agora.add(Duration(hours: esp.antecedenciaMinHoras));
    final maxima = agora.add(Duration(days: esp.antecedenciaMaxDias));
    final inicial = _data ?? minima;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(maxima) ? maxima : inicial,
      firstDate: DateTime(minima.year, minima.month, minima.day),
      lastDate: maxima,
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _data = escolhida;
      _ocupadas = const [];
    });
    await _carregarOcupadas();
  }

  Future<void> _carregarOcupadas() async {
    if (_data == null) return;
    setState(() => _aCarregarOcupadas = true);
    try {
      final c = Get.find<ReservasController>();
      final lista = await c.disponibilidade(widget.espaco.id, _ymd(_data!));
      if (!mounted) return;
      setState(() => _ocupadas = lista);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupadas = const []);
    } finally {
      if (mounted) setState(() => _aCarregarOcupadas = false);
    }
  }

  Future<void> _escolherHora(bool inicio) async {
    final atual = inicio ? _horaInicio : _horaFim;
    final escolhida = await showTimePicker(
      context: context,
      initialTime: atual ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      if (inicio) {
        _horaInicio = escolhida;
      } else {
        _horaFim = escolhida;
      }
    });
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, "0")}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  String _hm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';

  bool get _formValido => _data != null && _horaInicio != null && _horaFim != null;

  Future<void> _submeter() async {
    if (!_formValido) return;
    setState(() => _aEnviar = true);
    try {
      final c = Get.find<ReservasController>();
      final r = await c.criar(
        espacoId: widget.espaco.id,
        data: _ymd(_data!),
        horaInicio: _hm(_horaInicio!),
        horaFim: _hm(_horaFim!),
        motivo: _motivoCtrl.text.trim(),
      );
      if (!mounted) return;
      if (r['ok'] == true) {
        Get.back();
        Get.snackbar('Pedido enviado', 'Aguarda aprovação da gestão.',
            backgroundColor: AppColors.success, colorText: const Color(0xFFFFFFFF));
      } else {
        Get.snackbar('Não foi possível', r['erro']?.toString() ?? 'Erro desconhecido',
            backgroundColor: AppColors.dangerSoft, colorText: const Color(0xFFFFFFFF));
      }
    } finally {
      if (mounted) setState(() => _aEnviar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esp = widget.espaco;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(esp.nome),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumo do espaço
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Horário: ${esp.horaAbertura}–${esp.horaFecho}',
                    style: const TextStyle(color: AppColors.textMain, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Duração: ${esp.duracaoMinHoras}–${esp.duracaoMaxHoras} horas · Antecedência mín ${esp.antecedenciaMinHoras}h',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                if (esp.temCaucao) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Caução: ${esp.valorCaucao.toStringAsFixed(0)} Kz (transferência/depósito após aprovação)',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data
          _CampoSelector(
            label: 'Data',
            valor: _data == null ? 'Escolher data' : _ymd(_data!),
            onTap: _escolherData,
            icon: Icons.event,
          ),
          const SizedBox(height: 10),

          // Horarios ocupados (visivel quando ha data)
          if (_data != null) ...[
            if (_aCarregarOcupadas)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan))),
              )
            else if (_ocupadas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text('Sem reservas nesta data.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Já reservado:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _ocupadas
                          .map((o) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerSoft.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${o['hora_inicio']}–${o['hora_fim']}',
                                    style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _CampoSelector(
                  label: 'Início',
                  valor: _horaInicio == null ? 'Escolher' : _hm(_horaInicio!),
                  onTap: () => _escolherHora(true),
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CampoSelector(
                  label: 'Fim',
                  valor: _horaFim == null ? 'Escolher' : _hm(_horaFim!),
                  onTap: () => _escolherHora(false),
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _motivoCtrl,
            style: const TextStyle(color: AppColors.textMain, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Motivo (opcional)',
              hintStyle: const TextStyle(color: AppColors.textFaint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_aEnviar || !_formValido) ? null : _submeter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _aEnviar ? 'A enviar...' : 'Pedir reserva',
                style: const TextStyle(color: Color(0xFF0A0A1A), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A reserva ficará pendente até a gestão aprovar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CampoSelector extends StatelessWidget {
  final String label;
  final String valor;
  final VoidCallback onTap;
  final IconData icon;
  const _CampoSelector({required this.label, required this.valor, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(valor, style: const TextStyle(color: AppColors.textMain, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
