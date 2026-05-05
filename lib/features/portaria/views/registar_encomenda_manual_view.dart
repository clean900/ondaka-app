import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/portaria_encomendas_controller.dart';
import '../repositories/portaria_encomenda_repository.dart';

/// Form para o guarda registar manualmente uma encomenda que chegou
/// sem aviso prévio (Fluxo A).
///
/// Acedida via FAB do PortariaEncomendasShellView.
class RegistarEncomendaManualView extends StatefulWidget {
  const RegistarEncomendaManualView({super.key});

  @override
  State<RegistarEncomendaManualView> createState() =>
      _RegistarEncomendaManualViewState();
}

class _RegistarEncomendaManualViewState
    extends State<RegistarEncomendaManualView> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PortariaEncomendaRepository();

  final _descricaoCtrl = TextEditingController();
  final _remetenteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _pesquisaFraccaoCtrl = TextEditingController();

  List<Map<String, dynamic>> _fraccoes = [];
  Map<String, dynamic>? _fraccaoEscolhida;
  bool _aPesquisar = false;
  bool _aSubmeter = false;

  @override
  void initState() {
    super.initState();
    _carregarFraccoes();
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _remetenteCtrl.dispose();
    _notasCtrl.dispose();
    _pesquisaFraccaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarFraccoes({String? q}) async {
    setState(() => _aPesquisar = true);
    try {
      final res = await _repo.listarFraccoes(q: q);
      setState(() => _fraccoes = res);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _aPesquisar = false);
    }
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fraccaoEscolhida == null) {
      Get.snackbar('Imóvel obrigatório', 'Escolhe um imóvel da lista.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _aSubmeter = true);
    final controller = Get.find<PortariaEncomendasController>();

    final ok = await controller.registarManual(
      fraccaoId: _fraccaoEscolhida!['id'] as int,
      descricao: _descricaoCtrl.text.trim(),
      remetente: _remetenteCtrl.text.trim().isEmpty
          ? null
          : _remetenteCtrl.text.trim(),
      notas:
          _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _aSubmeter = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Registar encomenda'),
        backgroundColor: AppColors.bgDark,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Para uma encomenda que chegou sem aviso prévio.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Fracção
            const _Label('Imóvel *'),
            const SizedBox(height: 6),
            if (_fraccaoEscolhida != null)
              _FraccaoEscolhida(
                fraccao: _fraccaoEscolhida!,
                onLimpar: () => setState(() => _fraccaoEscolhida = null),
              )
            else
              _PesquisaFraccao(
                controller: _pesquisaFraccaoCtrl,
                onChanged: (q) => _carregarFraccoes(q: q),
                fraccoes: _fraccoes,
                aPesquisar: _aPesquisar,
                onEscolher: (f) {
                  setState(() {
                    _fraccaoEscolhida = f;
                    _pesquisaFraccaoCtrl.clear();
                  });
                },
              ),
            const SizedBox(height: 16),

            // Descrição
            const _Label('Descrição *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descricaoCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDeco('Ex: Caixa amarela DHL'),
              validator: (v) =>
                  v == null || v.trim().length < 3 ? 'Descrição obrigatória' : null,
            ),
            const SizedBox(height: 16),

            // Remetente
            const _Label('Remetente (opcional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _remetenteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Ex: Amazon, DHL, Continente'),
            ),
            const SizedBox(height: 16),

            // Notas
            const _Label('Notas do guarda (opcional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notasCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDeco('Observações...'),
            ),
            const SizedBox(height: 28),

            // Submeter
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aSubmeter ? null : _submeter,
                icon: _aSubmeter
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF001218),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_aSubmeter ? 'A registar...' : 'Registar encomenda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: const Color(0xFF001218),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FraccaoEscolhida extends StatelessWidget {
  const _FraccaoEscolhida({required this.fraccao, required this.onLimpar});
  final Map<String, dynamic> fraccao;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.home, color: AppColors.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Imóvel ${fraccao['identificador']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onLimpar,
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _PesquisaFraccao extends StatelessWidget {
  const _PesquisaFraccao({
    required this.controller,
    required this.onChanged,
    required this.fraccoes,
    required this.aPesquisar,
    required this.onEscolher,
  });

  final TextEditingController controller;
  final Function(String?) onChanged;
  final List<Map<String, dynamic>> fraccoes;
  final bool aPesquisar;
  final Function(Map<String, dynamic>) onEscolher;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Pesquisar imóvel (ex: 2B)...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: aPesquisar
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        if (fraccoes.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: fraccoes.map((f) {
                return InkWell(
                  onTap: () => onEscolher(f),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined,
                            color: AppColors.textMuted, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          'Imóvel ${f['identificador']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
