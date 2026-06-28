import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/models/visita.dart';
import '../repositories/portaria_repository.dart';
import '../services/portaria_features.dart';
import 'itens_visita_view.dart';

/// Ecrã mostrado após validação bem-sucedida.
/// Guarda vê info do visitante autorizado.
class ValidacaoSucessoView extends StatelessWidget {
  final Visita visita;
  final VoidCallback onProximo;
  final VoidCallback onFechar;

  const ValidacaoSucessoView({
    super.key,
    required this.visita,
    required this.onProximo,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    final visitante = visita.visitante;
    final fraccao = visita.fraccao;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Checkmark grande
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 3),
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.success,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Entrada autorizada!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Visitante pode entrar',
            style: TextStyle(
              color: AppColors.successSoft,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          // Card info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.person,
                  label: 'Visitante',
                  value: visitante?.nome ?? '—',
                ),
                _divider(),
                _infoRow(
                  icon: Icons.home,
                  label: 'Imóvel',
                  value: fraccao?.label ?? 'Imóvel #${visita.fraccaoId}',
                ),
                _divider(),
                _infoRow(
                  icon: Icons.login,
                  label: 'Entrada registada',
                  value: _formatarHora(visita.entrouEm),
                ),
                _divider(),
                _infoRow(
                  icon: Icons.key,
                  label: 'Método',
                  value: visita.metodoValidacao.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add-on Foto + conferência: foto do visitante (se activo).
          _FotoVisitante(visita: visita),

          // Add-on Registo de Viaturas: campo de matrícula (se activo).
          _CampoMatricula(visita: visita),

          // Add-on Controlo de Bens: botão só aparece se o add-on estiver activo.
          _BotaoRegistarItens(visita: visita),

          const SizedBox(height: 16),

          // Botão próximo
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onProximo,
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              label: const Text(
                'PRÓXIMO VISITANTE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botão voltar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onFechar,
              child: const Text(
                'Voltar ao início',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cyanSoft, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        color: Colors.white.withValues(alpha: 0.08),
        height: 1,
      );

  String _formatarHora(DateTime dt) {
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final seg = dt.second.toString().padLeft(2, '0');
    return '$hora:$min:$seg';
  }
}

/// Foto do visitante — só aparece se o add-on Foto + conferência estiver activo.
class _FotoVisitante extends StatefulWidget {
  final Visita visita;
  const _FotoVisitante({required this.visita});

  @override
  State<_FotoVisitante> createState() => _FotoVisitanteState();
}

class _FotoVisitanteState extends State<_FotoVisitante> {
  final _picker = ImagePicker();
  bool _activo = false;
  bool _enviando = false;
  String? _url;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    await PortariaFeatures.instance.garantirCarregado();
    if (mounted && PortariaFeatures.instance.ativo('foto_conferencia')) {
      setState(() => _activo = true);
    }
  }

  Future<void> _tirar() async {
    File? f;
    try {
      final img = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 70);
      if (img != null) f = File(img.path);
    } catch (_) {}
    if (f == null) return;
    setState(() => _enviando = true);
    try {
      final v = await PortariaRepository().registarFotoEntrada(widget.visita.id, f);
      if (mounted) setState(() => _url = v.fotoEntradaUrl);
    } catch (_) {
      Get.snackbar('Foto', 'Não foi possível guardar a foto.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_activo) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _url != null
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(_url!, width: 54, height: 54, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
                const SizedBox(width: 10),
                const Text('Foto do visitante registada',
                    style: TextStyle(color: AppColors.successSoft, fontWeight: FontWeight.w600)),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _enviando ? null : _tirar,
                icon: _enviando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanSoft))
                    : const Icon(Icons.photo_camera_outlined, color: AppColors.cyanSoft),
                label: const Text('Tirar foto do visitante',
                    style: TextStyle(color: AppColors.cyanSoft, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
    );
  }
}

/// Campo de matrícula — só aparece se o add-on Registo de Viaturas estiver activo.
class _CampoMatricula extends StatefulWidget {
  final Visita visita;
  const _CampoMatricula({required this.visita});

  @override
  State<_CampoMatricula> createState() => _CampoMatriculaState();
}

class _CampoMatriculaState extends State<_CampoMatricula> {
  final _ctrl = TextEditingController();
  bool _activo = false;
  bool _guardando = false;
  bool _guardada = false;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    await PortariaFeatures.instance.garantirCarregado();
    if (mounted && PortariaFeatures.instance.ativo('registo_viaturas')) {
      setState(() => _activo = true);
    }
  }

  Future<void> _guardar() async {
    final m = _ctrl.text.trim();
    if (m.isEmpty) return;
    setState(() => _guardando = true);
    try {
      await PortariaRepository().registarMatricula(widget.visita.id, m);
      if (mounted) setState(() => _guardada = true);
    } catch (_) {
      Get.snackbar('Matrícula', 'Não foi possível guardar.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_activo) return const SizedBox.shrink();
    if (_guardada) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: AppColors.successSoft, size: 18),
            const SizedBox(width: 8),
            Text('Matrícula ${_ctrl.text.trim()} registada',
                style: const TextStyle(color: AppColors.successSoft, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Matrícula do veículo (opcional)',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.directions_car_outlined, color: AppColors.cyanSoft),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cyan),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão "Registar itens" — só aparece se o add-on Controlo de Bens estiver
/// activo para a empresa (sonda o endpoint; 402 → esconde).
class _BotaoRegistarItens extends StatefulWidget {
  final Visita visita;
  const _BotaoRegistarItens({required this.visita});

  @override
  State<_BotaoRegistarItens> createState() => _BotaoRegistarItensState();
}

class _BotaoRegistarItensState extends State<_BotaoRegistarItens> {
  bool _activo = false;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    try {
      await PortariaRepository().listarItens(widget.visita.id);
      if (mounted) setState(() => _activo = true);
    } catch (_) {
      // AddonInativoException ou erro → mantém escondido
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_activo) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Get.to(
          () => ItensVisitaView(visita: widget.visita, modo: ModoItens.entrada),
        ),
        icon: const Icon(Icons.inventory_2_outlined, color: AppColors.cyanSoft),
        label: const Text('Registar itens trazidos',
            style: TextStyle(color: AppColors.cyanSoft, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
