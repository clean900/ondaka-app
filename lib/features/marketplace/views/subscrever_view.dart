import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../repositories/marketplace_repository.dart';

class SubscreverView extends StatefulWidget {
  const SubscreverView({super.key});

  @override
  State<SubscreverView> createState() => _SubscreverViewState();
}

class _SubscreverViewState extends State<SubscreverView> {
  final _repo = MarketplaceRepository();
  bool _aGerar = false;
  String? _entidade;
  int? _referencia;
  double? _montante;
  String? _erro;

  Future<void> _gerar() async {
    setState(() { _aGerar = true; _erro = null; });
    final r = await _repo.subscrever();
    setState(() {
      _aGerar = false;
      if (r.sucesso) {
        _entidade = r.entidade;
        _referencia = r.referencia;
        _montante = r.montante;
      } else {
        _erro = r.erro;
      }
    });
  }

  String _kz(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} Kz';

  @override
  Widget build(BuildContext context) {
    final temRef = _referencia != null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Subscrever Marketplace'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecalho
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text('Publique no Marketplace',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('Anuncie produtos e serviços aos seus vizinhos durante 30 dias.',
                      style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!temRef) ...[
              _linha(Icons.check_circle_outline, 'Publique anúncios à vontade durante 30 dias'),
              _linha(Icons.check_circle_outline, 'Produtos e serviços, com fotos'),
              _linha(Icons.check_circle_outline, 'Escolha quem vê: o seu condomínio ou toda a rede'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subscrição 30 dias', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                    const Text('5.000 Kz',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.cyan)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: AppColors.dangerSoft, fontSize: 13)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: const Color(0xFF001218),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _aGerar ? null : _gerar,
                child: Text(_aGerar ? 'A gerar referência...' : 'Gerar referência de pagamento',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ] else ...[
              // Referencia gerada
              const Text('Pague esta referência',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textMain)),
              const SizedBox(height: 4),
              const Text('Multicaixa, ATM ou app do seu banco',
                  style: TextStyle(fontSize: 13, color: AppColors.textFaint)),
              const SizedBox(height: 16),
              _refLinha('Entidade', _entidade ?? '—'),
              _refLinha('Referência', _referencia?.toString() ?? '—'),
              _refLinha('Montante', _montante != null ? _kz(_montante!) : '—'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Após o pagamento, a sua subscrição activa automaticamente. Pode fechar este ecrã.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Concluído'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linha(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14, color: AppColors.textMuted))),
        ],
      ),
    );
  }

  Widget _refLinha(String label, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textFaint)),
          Row(
            children: [
              Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMain)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: valor.replaceAll('.', '').replaceAll(' Kz', '')));
                  Get.snackbar('Copiado', '$label copiado.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.surface, colorText: AppColors.textMain,
                      duration: const Duration(seconds: 1));
                },
                child: const Icon(Icons.copy, size: 16, color: AppColors.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
