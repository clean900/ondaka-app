import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../models/reserva_models.dart';
import '../repositories/reservas_repository.dart';

class MinhasReservasView extends StatefulWidget {
  const MinhasReservasView({super.key});

  @override
  State<MinhasReservasView> createState() => _MinhasReservasViewState();
}

class _MinhasReservasViewState extends State<MinhasReservasView> {
  final _repo = ReservasRepository();
  List<MinhaReserva> _lista = const [];
  bool _aCarregar = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _aCarregar = true;
      _erro = null;
    });
    try {
      final r = await _repo.minhas();
      if (!mounted) return;
      setState(() => _lista = r);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar as suas reservas.');
    } finally {
      if (mounted) setState(() => _aCarregar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Minhas reservas'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: _aCarregar && _lista.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : _erro != null && _lista.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_erro!, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : _lista.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Ainda não fez nenhuma reserva.\nVá a Reservas para pedir uma.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.cyan,
                      backgroundColor: AppColors.surface,
                      onRefresh: _carregar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ReservaCard(reserva: _lista[i], onActualizar: _carregar),
                      ),
                    ),
    );
  }
}

class _ReservaCard extends StatefulWidget {
  final MinhaReserva reserva;
  final Future<void> Function() onActualizar;
  const _ReservaCard({required this.reserva, required this.onActualizar});

  @override
  State<_ReservaCard> createState() => _ReservaCardState();
}

class _ReservaCardState extends State<_ReservaCard> {
  bool _aEnviar = false;

  Future<void> _enviarComprovativo() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (foto == null || !mounted) return;
    setState(() => _aEnviar = true);
    try {
      final repo = ReservasRepository();
      final r = await repo.enviarComprovativo(widget.reserva.id, File(foto.path));
      if (!mounted) return;
      if (r['ok'] == true) {
        Get.snackbar('Enviado', 'Comprovativo enviado. A gestão vai confirmar.',
            backgroundColor: AppColors.success, colorText: const Color(0xFFFFFFFF));
        await widget.onActualizar();
      } else {
        Get.snackbar('Erro', r['erro']?.toString() ?? 'Falha no envio',
            backgroundColor: AppColors.dangerSoft, colorText: const Color(0xFFFFFFFF));
      }
    } finally {
      if (mounted) setState(() => _aEnviar = false);
    }
  }

  ({Color cor, String label}) _estadoVisual() {
    final reserva = widget.reserva;
    switch (reserva.estado) {
      case 'pendente':
        return (cor: AppColors.warning, label: 'Pendente');
      case 'aprovada':
        return (cor: AppColors.cyan, label: 'Aprovada');
      case 'aguarda_caucao':
        return (cor: AppColors.warning, label: 'Aguarda caução');
      case 'confirmada':
        return (cor: AppColors.success, label: 'Confirmada');
      case 'recusada':
        return (cor: AppColors.danger, label: 'Recusada');
      case 'cancelada':
        return (cor: AppColors.textFaint, label: 'Cancelada');
      default:
        return (cor: AppColors.textMuted, label: reserva.estado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    final v = _estadoVisual();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(reserva.espacoNome,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: v.cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(v.label, style: TextStyle(color: v.cor, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${reserva.data} · ${reserva.horaInicio}–${reserva.horaFim}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (reserva.motivo != null && reserva.motivo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('"${reserva.motivo}"',
                style: const TextStyle(color: AppColors.textFaint, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
          if (reserva.estado == 'aguarda_caucao') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caução: ${reserva.espacoValorCaucao.toStringAsFixed(0)} Kz',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pague por transferência ou depósito e envie o comprovativo à gestão.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  if (reserva.comprovativoCaucao != null && reserva.comprovativoCaucao!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text('✓ Comprovativo enviado, a aguardar confirmação.',
                        style: TextStyle(color: AppColors.success, fontSize: 11)),
                  ] else ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _aEnviar ? null : _enviarComprovativo,
                        icon: const Icon(Icons.upload_file, size: 16, color: Color(0xFF0A0A1A)),
                        label: Text(
                          _aEnviar ? 'A enviar...' : 'Enviar comprovativo',
                          style: const TextStyle(color: Color(0xFF0A0A1A), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
