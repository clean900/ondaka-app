import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../controllers/pagamento_controller.dart';
import '../models/pagamento.dart';

/// Formulário para o condómino submeter um novo pagamento.
///
/// Pode ser usado para criar (pagamento=null) ou editar (pagamento!=null).
class PagamentoFormView extends StatefulWidget {
  const PagamentoFormView({super.key, this.pagamento});
  final Pagamento? pagamento;

  @override
  State<PagamentoFormView> createState() => _PagamentoFormViewState();
}

class _PagamentoFormViewState extends State<PagamentoFormView> {
  final _formKey = GlobalKey<FormState>();
  final _refExternaController = TextEditingController();
  final _bancoController = TextEditingController();
  final _notasController = TextEditingController();
  final _picker = ImagePicker();

  // Lançamentos disponíveis
  List<Map<String, dynamic>> _lancamentos = [];
  Set<int> _lancamentosSelecionados = {};
  bool _carregandoLancamentos = true;

  // Estado do form
  Map<String, dynamic>? _coordenadas;
  Map<String, dynamic>? _referenciaMcxGerada;
  String _metodo = 'transferencia_bancaria';
  DateTime _dataPagamento = DateTime.now();
  File? _comprovativo;
  int? _fraccaoId;

  @override
  void initState() {
    super.initState();
    _carregarLancamentos();
    _carregarCoordenadas();
  }

  Future<void> _carregarCoordenadas() async {
    try {
      final r = await ApiService.to.dio
          .get('/extracto/pagamentos/coordenadas-bancarias');
      if (mounted && r.data['data'] != null) {
        setState(() => _coordenadas = r.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // silenciar — coordenadas opcionais
    }
  }

  Future<void> _copiar(String texto, String label) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) {
      Get.snackbar('Copiado', '\$label copiado para o clipboard.',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 2));
    }
  }

  Future<void> _carregarLancamentos() async {
    try {
      final r = await ApiService.to.dio
          .get('/extracto/pagamentos/lancamentos-em-aberto');
      final lista = (r.data['data'] as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _lancamentos = lista;
          if (lista.isNotEmpty) {
            _fraccaoId = (lista.first['fraccao'] as Map)['id'] as int;
            // Pré-selecionar todos por defeito
            _lancamentosSelecionados =
                lista.map((l) => l['id'] as int).toSet();
          }
          _carregandoLancamentos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregandoLancamentos = false);
    }
  }

  double get _totalSelecionado {
    return _lancamentos
        .where((l) => _lancamentosSelecionados.contains(l['id'] as int))
        .fold<double>(0, (sum, l) {
      return sum +
          (double.tryParse(l['valor_em_divida'].toString()) ?? 0.0);
    });
  }

  Future<void> _escolherImagem() async {
    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (imagem != null && mounted) {
      setState(() => _comprovativo = File(imagem.path));
    }
  }

  Future<void> _tirarFoto() async {
    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (imagem != null && mounted) {
      setState(() => _comprovativo = File(imagem.path));
    }
  }

  Future<void> _gerarReferenciaMcx() async {
    if (_lancamentosSelecionados.isEmpty) {
      Get.snackbar('Atenção', 'Escolhe pelo menos um lançamento a pagar.',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }

    if (_fraccaoId == null) return;

    final controller = Get.put(PagamentoController());

    // 1. Submeter o pagamento (sem comprovativo)
    final ok = await controller.submeter(
      fraccaoId: _fraccaoId!,
      metodo: 'proxypay_rps',
      valor: _totalSelecionado,
      dataPagamento: DateTime.now(),
      lancamentoIds: _lancamentosSelecionados.toList(),
    );

    if (!ok || !mounted) {
      Get.snackbar('Erro', controller.erro.value ?? 'Erro ao submeter.',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }

    // 2. Gerar referência ProxyPay no último pagamento criado
    final ultimo = controller.pagamentos.first;
    final ref = await controller.gerarReferenciaMcx(ultimo.id);

    if (ref != null && mounted) {
      setState(() => _referenciaMcxGerada = ref);
    } else if (mounted) {
      Get.snackbar('Erro', controller.erro.value ?? 'Erro ao gerar referência.',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
    }
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lancamentosSelecionados.isEmpty) {
      Get.snackbar('Atenção', 'Escolhe pelo menos um lançamento a pagar.',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }

    final exigeComprovativo = _metodo == 'transferencia_bancaria' ||
        _metodo == 'deposito_bancario';
    if (exigeComprovativo && _comprovativo == null) {
      Get.snackbar(
        'Comprovativo obrigatório',
        'Para transferência ou depósito é obrigatório anexar comprovativo.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    if (_fraccaoId == null) return;

    final controller = Get.put(PagamentoController());
    final ok = await controller.submeter(
      fraccaoId: _fraccaoId!,
      metodo: _metodo,
      valor: _totalSelecionado,
      dataPagamento: _dataPagamento,
      lancamentoIds: _lancamentosSelecionados.toList(),
      referenciaExterna: _refExternaController.text.trim().isEmpty
          ? null
          : _refExternaController.text.trim(),
      bancoOrigem: _bancoController.text.trim().isEmpty
          ? null
          : _bancoController.text.trim(),
      notasCondomino: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
      comprovativo: _comprovativo,
    );

    if (ok && mounted) {
      Get.back();
      Get.snackbar('Pagamento submetido',
          'Aguarda validação do administrador.',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    } else if (mounted) {
      Get.snackbar('Erro', controller.erro.value ?? 'Erro ao submeter.',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(
      locale: 'pt_PT',
      symbol: 'Kz',
      decimalDigits: 2,
    );
    final formatadorData = DateFormat('d MMM yyyy', 'pt_PT');
    final controller = Get.put(PagamentoController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Submeter pagamento'),
        backgroundColor: AppColors.bgDark,
      ),
      body: _carregandoLancamentos
          ? const Center(child: CircularProgressIndicator())
          : _lancamentos.isEmpty
              ? _vazio()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Lançamentos a pagar
                      _seccao(
                        'Escolhe o que pagar',
                        Column(
                          children: _lancamentos.map((l) {
                            final id = l['id'] as int;
                            final selecionado =
                                _lancamentosSelecionados.contains(id);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.cyan,
                              value: selecionado,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _lancamentosSelecionados.add(id);
                                  } else {
                                    _lancamentosSelecionados.remove(id);
                                  }
                                });
                              },
                              title: Text(
                                l['descricao'].toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                              subtitle: Text(
                                formatador.format(double.tryParse(
                                        l['valor_em_divida'].toString()) ??
                                    0),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Total
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total a pagar',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              formatador.format(_totalSelecionado),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),

                      // Método
                      _seccao(
                        'Método de pagamento',
                        Column(
                          children: [
                            _radioMetodo('transferencia_bancaria',
                                'Transferência bancária',
                                Icons.swap_horiz),
                            _radioMetodo('deposito_bancario',
                                'Depósito bancário', Icons.account_balance),
                            _radioMetodo('proxypay_rps',
                                'Multicaixa Express',
                                Icons.qr_code_2),
                            _radioMetodo('dinheiro', 'Dinheiro',
                                Icons.payments_outlined),
                            _radioMetodo(
                                'outro', 'Outro', Icons.more_horiz_outlined),
                          ],
                        ),
                      ),

                      // Coordenadas bancárias (só para transferência/depósito)
                      if (_coordenadas != null &&
                          (_metodo == 'transferencia_bancaria' ||
                              _metodo == 'deposito_bancario'))
                        _coordenadasCard(),

                      // Data
                      _seccao(
                        'Data do pagamento',
                        InkWell(
                          onTap: () async {
                            final escolhida = await showDatePicker(
                              context: context,
                              initialDate: _dataPagamento,
                              firstDate:
                                  DateTime.now().subtract(const Duration(days: 90)),
                              lastDate: DateTime.now(),
                            );
                            if (escolhida != null) {
                              setState(() => _dataPagamento = escolhida);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: AppColors.cyan, size: 18),
                                const SizedBox(width: 10),
                                Text(formatadorData.format(_dataPagamento),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Comprovativo (obrigatório para transf/depósito)
                      _seccao(
                        'Comprovativo',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_comprovativo != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: FileImage(_comprovativo!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _tirarFoto,
                                    icon: const Icon(Icons.camera_alt_outlined,
                                        size: 16),
                                    label: const Text('Tirar foto'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.2)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _escolherImagem,
                                    icon: const Icon(Icons.image_outlined,
                                        size: 16),
                                    label: const Text('Galeria'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.2)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Detalhes opcionais
                      _seccao(
                        'Detalhes (opcional)',
                        Column(
                          children: [
                            _input('Referência da transferência',
                                _refExternaController,
                                hint: 'Ex: TRF-BFA-202612345'),
                            const SizedBox(height: 10),
                            _input('Banco de origem', _bancoController,
                                hint: 'Ex: BFA'),
                            const SizedBox(height: 10),
                            _input('Notas para o admin', _notasController,
                                hint: 'Mensagem opcional', linhas: 3),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card com referência gerada (MCX)
                      if (_referenciaMcxGerada != null)
                        _refMcxCard()
                      else if (_metodo == 'proxypay_rps')
                        // Botão gerar referência MCX
                        Obx(() => SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: controller.isSubmitting.value
                                    ? null
                                    : _gerarReferenciaMcx,
                                icon: const Icon(Icons.qr_code_2),
                                label: controller.isSubmitting.value
                                    ? const Text('A gerar referência...')
                                    : const Text('Gerar referência'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cyan,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ))
                      else
                        // Botão submeter (outros métodos)
                        Obx(() => SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: controller.isSubmitting.value
                                    ? null
                                    : _submeter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cyan,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: controller.isSubmitting.value
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text('Submeter pagamento',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                              ),
                            )),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _refMcxCard() {
    final ref = _referenciaMcxGerada!;
    final formatador = NumberFormat.currency(
      locale: 'pt_PT',
      symbol: 'Kz',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('Referência gerada!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Paga no Multicaixa Express, ATM ou balcão do banco.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _refLinha('Entidade', ref['entity_id'].toString(), copiar: true),
                _refLinha('Referência', ref['reference_id'].toString(), copiar: true),
                _refLinha('Valor', formatador.format(double.tryParse(ref['amount'].toString()) ?? 0)),
                if (ref['expira_em'] != null)
                  _refLinha('Validade', 'até ' + ref['expira_em'].toString()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Concluído'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refLinha(String label, String valor, {bool copiar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
          if (copiar)
            InkWell(
              onTap: () => _copiar(valor, label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Copiar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coordenadasCard() {
    final c = _coordenadas!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_outlined,
                  color: AppColors.cyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Faz a transferência para',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (c['banco_nome'] != null) _coordLinha('Banco', c['banco_nome'].toString()),
          if (c['titular_conta'] != null)
            _coordLinha('Titular', c['titular_conta'].toString()),
          if (_metodo == 'transferencia_bancaria' && c['iban'] != null)
            _coordLinha('IBAN', c['iban'].toString(), copiar: true),
          if (_metodo == 'deposito_bancario' && c['numero_conta'] != null)
            _coordLinha('Nº conta', c['numero_conta'].toString(), copiar: true),
          if (c['nif_emissor'] != null)
            _coordLinha('NIF', c['nif_emissor'].toString(), copiar: true),
          if (c['observacoes_facturacao'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c['observacoes_facturacao'].toString(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _coordLinha(String label, String valor, {bool copiar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (copiar)
            InkWell(
              onTap: () => _copiar(valor, label),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 12, color: AppColors.cyan),
                    SizedBox(width: 4),
                    Text('Copiar',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Estás em dia!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Não tens lançamentos em aberto neste momento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccao(String titulo, Widget conteudo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          conteudo,
        ],
      ),
    );
  }

  Widget _radioMetodo(String valor, String label, IconData icone) {
    final selecionado = _metodo == valor;
    return InkWell(
      onTap: () => setState(() => _metodo = valor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selecionado
              ? AppColors.cyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado
                ? AppColors.cyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icone,
                color: selecionado ? AppColors.cyan : AppColors.textMuted,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: selecionado ? Colors.white : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight:
                        selecionado ? FontWeight.w600 : FontWeight.w400,
                  )),
            ),
            if (selecionado)
              const Icon(Icons.check_circle, color: AppColors.cyan, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller,
      {String? hint, int linhas = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: linhas,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }
}
