import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/chamada_repository.dart';
import '../services/webrtc_call_service.dart';

/// Ecrã para iniciar uma chamada de voz. Mostra os destinos permitidos
/// (matriz por papel vinda do backend). Para "morador" pede o imóvel.
class LigarView extends StatefulWidget {
  const LigarView({super.key});

  @override
  State<LigarView> createState() => _LigarViewState();
}

class _LigarViewState extends State<LigarView> {
  final _repo = ChamadaRepository();
  Destinos? _info;
  bool _carregando = true;
  String? _erro;

  // Quando o destino é "morador", mostramos a lista de imóveis.
  bool _escolherImovel = false;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final info = await _repo.destinos();
      if (mounted) setState(() { _info = info; _carregando = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = 'Não foi possível carregar.'; _carregando = false; });
    }
  }

  Future<void> _ligar(String destino, {int? fraccaoId}) async {
    try {
      await WebrtcCallService.to.iniciar(destino: destino, fraccaoId: fraccaoId);
    } on Object catch (e) {
      final s = e.toString();
      final msg = s.contains('422')
          ? 'Este destino não tem ninguém com a app.'
          : s.contains('403')
              ? 'Sem permissão para esta chamada.'
              : 'Não foi possível ligar.';
      Get.snackbar('Chamada', msg, snackPosition: SnackPosition.BOTTOM);
    }
  }

  ({IconData icon, String titulo, String sub}) _rotulo(String destino) {
    switch (destino) {
      case 'portaria':
        return (icon: Icons.shield_outlined, titulo: 'Portaria', sub: 'Falar com o segurança');
      case 'morador':
        return (icon: Icons.home_outlined, titulo: 'Morador', sub: 'Escolher o imóvel');
      case 'gestor':
        return (icon: Icons.badge_outlined, titulo: 'Gestor', sub: 'Falar com a administração');
      default:
        return (icon: Icons.call, titulo: destino, sub: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(_escolherImovel ? 'Escolher imóvel' : 'Ligar'),
        backgroundColor: Colors.transparent,
        leading: _escolherImovel
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() { _escolherImovel = false; _filtro = ''; }),
              )
            : null,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: AppColors.textMuted)))
              : _escolherImovel
                  ? _listaImoveis()
                  : _listaDestinos(),
    );
  }

  Widget _listaDestinos() {
    final destinos = _info?.destinos ?? const [];
    if (destinos.isEmpty) {
      return const Center(child: Text('Sem destinos disponíveis.', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        const Text('Para quem quer ligar?',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 16),
        ...destinos.map((d) {
          final r = _rotulo(d);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
                  child: Icon(r.icon, color: Colors.white),
                ),
                title: Text(r.titulo,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 17, fontWeight: FontWeight.w600)),
                subtitle: Text(r.sub, style: const TextStyle(color: AppColors.textMuted)),
                trailing: const Icon(Icons.call, color: AppColors.success),
                onTap: () {
                  if (d == 'morador') {
                    setState(() => _escolherImovel = true);
                  } else {
                    _ligar(d);
                  }
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _listaImoveis() {
    final fraccoes = _info?.fraccoes ?? const [];
    final lista = _filtro.isEmpty
        ? fraccoes
        : fraccoes.where((f) => f.identificador.toLowerCase().contains(_filtro.toLowerCase())).toList();
    return Column(
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
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        title: Text(f.identificador, style: const TextStyle(color: AppColors.textMain)),
                        trailing: const Icon(Icons.call, color: AppColors.success),
                        onTap: () => _ligar('morador', fraccaoId: f.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
