import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/portaria_repository.dart';

/// Verificação proativa da Lista Negra: o guarda introduz BI, matrícula e/ou
/// nome de um visitante avulso e confirma se consta na lista negra ANTES de
/// autorizar a entrada (complementa o alerta reativo na validação de QR/OTP).
class VerificarVisitanteView extends StatefulWidget {
  const VerificarVisitanteView({super.key});

  @override
  State<VerificarVisitanteView> createState() => _VerificarVisitanteViewState();
}

class _VerificarVisitanteViewState extends State<VerificarVisitanteView> {
  final _repo = PortariaRepository();
  final _nome = TextEditingController();
  final _bi = TextEditingController();
  final _matricula = TextEditingController();

  bool _ocupado = false;
  bool _verificado = false;
  Map<String, dynamic>? _alerta; // != null => banido
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _bi.dispose();
    _matricula.dispose();
    super.dispose();
  }

  bool get _temDados =>
      _nome.text.trim().isNotEmpty ||
      _bi.text.trim().isNotEmpty ||
      _matricula.text.trim().isNotEmpty;

  Future<void> _verificar() async {
    if (!_temDados || _ocupado) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _erro = null;
      _verificado = false;
      _alerta = null;
    });
    try {
      final alerta = await _repo.verificarListaNegra(
        bi: _bi.text.trim().isEmpty ? null : _bi.text.trim(),
        matricula:
            _matricula.text.trim().isEmpty ? null : _matricula.text.trim(),
        nome: _nome.text.trim().isEmpty ? null : _nome.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _alerta = alerta;
        _verificado = true;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _erro =
          e.response?.data?['message']?.toString() ?? 'Erro ao verificar.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível verificar. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Verificar visitante'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirma se um visitante consta na Lista Negra antes de '
              'autorizar a entrada. Preenche pelo menos um campo.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            _campo(_nome, 'Nome do visitante', Icons.person_outline),
            const SizedBox(height: 12),
            _campo(_bi, 'Nº de BI', Icons.badge_outlined),
            const SizedBox(height: 12),
            _campo(_matricula, 'Matrícula do veículo', Icons.directions_car_outlined),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: (_temDados && !_ocupado) ? _verificar : null,
              icon: _ocupado
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_ocupado ? 'A verificar…' : 'Verificar'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.bgDark,
              ),
            ),
            const SizedBox(height: 20),
            if (_erro != null) _caixaErro(_erro!),
            if (_verificado && _alerta != null) _bannerListaNegra(_alerta!),
            if (_verificado && _alerta == null) _caixaLimpo(),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textMain),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.cyanSoft),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }

  Widget _caixaErro(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg,
          style: const TextStyle(color: AppColors.dangerSoft, fontSize: 13)),
    );
  }

  /// Banner vermelho: visitante consta na lista negra.
  Widget _bannerListaNegra(Map<String, dynamic> alerta) {
    final motivo = alerta['motivo']?.toString();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFB91C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gpp_bad, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ LISTA NEGRA',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(
                  alerta['mensagem']?.toString() ??
                      'Este visitante consta na lista negra do condomínio.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                if (motivo != null && motivo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Motivo: $motivo',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Caixa verde: visitante não consta na lista negra.
  Widget _caixaLimpo() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sem registo na Lista Negra. Pode prosseguir com a verificação '
              'normal de entrada.',
              style: TextStyle(color: AppColors.successSoft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
