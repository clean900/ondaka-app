import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../models/nps_pedido.dart';
import '../repositories/nps_repository.dart';

/// Inquérito NPS para um pedido (condomínio ou plataforma).
/// Mostra escala 0-10, depois comentário + seguimento, e grava.
class NpsInqueritoView extends StatefulWidget {
  final NpsPedido pedido;
  const NpsInqueritoView({super.key, required this.pedido});

  @override
  State<NpsInqueritoView> createState() => _NpsInqueritoViewState();
}

class _NpsInqueritoViewState extends State<NpsInqueritoView> {
  final _repo = NpsRepository();
  final _comentario = TextEditingController();
  final _seguimento = TextEditingController();
  int? _nota;
  bool _aEnviar = false;

  @override
  void dispose() {
    _comentario.dispose();
    _seguimento.dispose();
    super.dispose();
  }

  Color _corNota(int n) {
    if (n <= 6) return AppColors.dangerSoft;
    if (n <= 8) return AppColors.warning;
    return AppColors.cyan;
  }

  Future<void> _enviar() async {
    if (_nota == null) return;
    setState(() => _aEnviar = true);
    try {
      final ok = await _repo.responder(
        alvo: widget.pedido.alvo,
        nota: _nota!,
        comentario: _comentario.text.trim(),
        seguimento: _seguimento.text.trim(),
      );
      setState(() => _aEnviar = false);
      if (ok) {
        Get.back(result: true);
        Get.snackbar('Obrigado!', 'A sua avaliação foi registada.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF1D9E75), colorText: const Color(0xFFFFFFFF));
      } else {
        Get.snackbar('Erro', 'Resposta inesperada do servidor.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.dangerSoft, colorText: const Color(0xFFFFFFFF));
      }
    } on dio.DioException catch (e) {
      setState(() => _aEnviar = false);
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? 'erro';
      Get.snackbar('Erro $code', body.length > 120 ? body.substring(0, 120) : body,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.dangerSoft, colorText: const Color(0xFF001218));
    } catch (e) {
      setState(() => _aEnviar = false);
      Get.snackbar('Erro', e.toString().length > 120 ? e.toString().substring(0, 120) : e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.dangerSoft, colorText: const Color(0xFF001218));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Avaliação'),
        backgroundColor: AppColors.bgDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pedido.titulo,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textMain)),
            const SizedBox(height: 8),
            Text(widget.pedido.pergunta,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 24),

            // Escala 0-10
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(11, (n) {
                final sel = _nota == n;
                return GestureDetector(
                  onTap: () => setState(() => _nota = n),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? _corNota(n) : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? _corNota(n) : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text('$n',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: sel ? const Color(0xFF001218) : AppColors.textMain,
                        )),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nada provável', style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
                Text('Muito provável', style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
              ],
            ),
            const SizedBox(height: 24),

            // Comentario
            const Text('Comentário (opcional)',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _comentario,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'O que achou?',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Seguimento
            Text(widget.pedido.seguimento,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _seguimento,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'A sua sugestão...',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: const Color(0xFF001218),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: (_nota == null || _aEnviar) ? null : _enviar,
              child: Text(_aEnviar ? 'A enviar...' : 'Enviar avaliação',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
