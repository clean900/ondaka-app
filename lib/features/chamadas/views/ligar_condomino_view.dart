import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/chamada_repository.dart';

/// Guarda escolhe um imóvel e liga ao morador (chamada de voz).
class LigarCondominoView extends StatefulWidget {
  const LigarCondominoView({super.key});

  @override
  State<LigarCondominoView> createState() => _LigarCondominoViewState();
}

class _LigarCondominoViewState extends State<LigarCondominoView> {
  final _repo = ChamadaRepository();
  List<({int id, String identificador})> _fraccoes = [];
  bool _carregando = true;
  int? _aLigar;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final f = await _repo.fraccoes();
      if (mounted) setState(() { _fraccoes = f; _carregando = false; });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _ligar(int fraccaoId) async {
    if (_aLigar != null) return;
    setState(() => _aLigar = fraccaoId);
    try {
      final url = await _repo.ligarCondomino(fraccaoId);
      final audio = '$url#config.startAudioOnly=true&config.startWithVideoMuted=true';
      final uri = Uri.parse(audio);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } on Object catch (e) {
      final msg = e.toString().contains('422')
          ? 'Este imóvel não tem morador com app.'
          : 'Não foi possível ligar.';
      Get.snackbar('Chamada', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _aLigar = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtro.isEmpty
        ? _fraccoes
        : _fraccoes.where((f) => f.identificador.toLowerCase().contains(_filtro.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Ligar ao morador'), backgroundColor: Colors.transparent),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setState(() => _filtro = v),
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'Procurar imóvel...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.cyanSoft),
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
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? const Center(child: Text('Sem imóveis.', style: TextStyle(color: AppColors.textMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: lista.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final f = lista[i];
                            final aLigar = _aLigar == f.id;
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                title: Text(f.identificador, style: const TextStyle(color: AppColors.textMain)),
                                trailing: aLigar
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.call, color: AppColors.success),
                                onTap: aLigar ? null : () => _ligar(f.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
