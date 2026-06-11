import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/sos_controller.dart';
import '../models/tipo_sos.dart';
import 'sos_detalhe_view.dart';

/// Bottomsheet de SOS — fluxo completo de envio de alerta.
///
/// Composição:
///  - Step 1: lista de tipos (críticos sempre visíveis + outras em accordéon)
///  - Step 2: confirmação com localização + descrição
///  - Modal final: alerta enviado
class SosBottomsheet {
  static Future<void> abrir(BuildContext context) async {
    final controller = Get.put(SosController());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => _SosSheet(
          controller: controller,
          scrollController: scrollController,
        ),
      ),
    );

    // Cleanup do GetX controller após fechar
    if (Get.isRegistered<SosController>()) {
      Get.delete<SosController>();
    }
  }
}

class _SosSheet extends StatefulWidget {
  final SosController controller;
  final ScrollController scrollController;

  const _SosSheet({required this.controller, required this.scrollController});

  @override
  State<_SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends State<_SosSheet> {
  TipoSos? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Conteúdo
          Expanded(
            child: Obx(() {
              if (widget.controller.isLoading.value && widget.controller.tipos.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.danger));
              }

              if (widget.controller.erro.value != null && widget.controller.tipos.isEmpty) {
                return _erroState();
              }

              if (_selected == null) {
                return _StepSelecaoTipo(
                  controller: widget.controller,
                  scrollController: widget.scrollController,
                  onSelected: (t) => setState(() => _selected = t),
                );
              }

              return _StepEnvio(
                controller: widget.controller,
                tipo: _selected!,
                scrollController: widget.scrollController,
                onBack: () => setState(() => _selected = null),
                onEnviado: (alerta) async {
                  await _mostrarSucesso(alerta);
                  if (mounted) Navigator.of(context).pop();
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarSucesso(AlertaCriado alerta) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Alerta enviado', style: TextStyle(color: AppColors.textMain)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alerta.message,
              style: const TextStyle(color: AppColors.textMain, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'ID #${alerta.id}',
                    style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Get.to(() => SosDetalheView(alertaId: alerta.id));
            },
            child: const Text('Ver detalhes', style: TextStyle(color: AppColors.cyan)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _erroState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              widget.controller.erro.value ?? 'Erro',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => widget.controller.carregar(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STEP 1 — Selecção do tipo
// ============================================================================
class _StepSelecaoTipo extends StatelessWidget {
  final SosController controller;
  final ScrollController scrollController;
  final ValueChanged<TipoSos> onSelected;

  const _StepSelecaoTipo({
    required this.controller,
    required this.scrollController,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emergency_outlined, color: AppColors.danger, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergência SOS',
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Selecciona o tipo de emergência',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Críticos — sempre visíveis no topo (destacados)
              _SecaoCritica(controller: controller, onSelected: onSelected),
              const SizedBox(height: 16),

              // Outras gravidades — em accordéon
              _GravidadeAccordeon(
                controller: controller,
                gravidade: GravidadeSos.alto,
                titulo: 'Alto risco',
                subtitulo: '4 tipos',
                onSelected: onSelected,
              ),
              const SizedBox(height: 8),
              _GravidadeAccordeon(
                controller: controller,
                gravidade: GravidadeSos.medio,
                titulo: 'Médio',
                subtitulo: '2 tipos',
                onSelected: onSelected,
              ),
              const SizedBox(height: 8),
              _GravidadeAccordeon(
                controller: controller,
                gravidade: GravidadeSos.baixo,
                titulo: 'Baixo / reporte',
                subtitulo: '2 tipos',
                onSelected: onSelected,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SECÇÃO CRÍTICA (sempre visível)
// ============================================================================
class _SecaoCritica extends StatelessWidget {
  final SosController controller;
  final ValueChanged<TipoSos> onSelected;

  const _SecaoCritica({required this.controller, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final criticos = controller.tiposPorGravidade(GravidadeSos.critico);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.priority_high, color: AppColors.danger, size: 18),
            const SizedBox(width: 6),
            const Text(
              'CRÍTICO — Vida em perigo',
              style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...criticos.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CardTipoCritico(tipo: t, onTap: () => onSelected(t)),
        )),
      ],
    );
  }
}

class _CardTipoCritico extends StatelessWidget {
  final TipoSos tipo;
  final VoidCallback onTap;

  const _CardTipoCritico({required this.tipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tipo.icone, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                tipo.label,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.danger, size: 22),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ACCORDEON por gravidade (Alto / Médio / Baixo)
// ============================================================================
class _GravidadeAccordeon extends StatelessWidget {
  final SosController controller;
  final GravidadeSos gravidade;
  final String titulo;
  final String subtitulo;
  final ValueChanged<TipoSos> onSelected;

  const _GravidadeAccordeon({
    required this.controller,
    required this.gravidade,
    required this.titulo,
    required this.subtitulo,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tipos = controller.tiposPorGravidade(gravidade);
    final cor = _corDe(gravidade);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconeDe(gravidade), color: cor, size: 18),
          ),
          title: Text(
            titulo,
            style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitulo,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          iconColor: cor,
          collapsedIconColor: AppColors.textMuted,
          children: tipos.map((t) => _ItemTipoLista(tipo: t, cor: cor, onTap: () => onSelected(t))).toList(),
        ),
      ),
    );
  }

  Color _corDe(GravidadeSos g) {
    return switch (g) {
      GravidadeSos.alto => Color(0xFFEA580C),
      GravidadeSos.medio => AppColors.warning,
      GravidadeSos.baixo => AppColors.success,
      _ => AppColors.cyan,
    };
  }

  IconData _iconeDe(GravidadeSos g) {
    return switch (g) {
      GravidadeSos.alto => Icons.warning_amber_outlined,
      GravidadeSos.medio => Icons.info_outline,
      GravidadeSos.baixo => Icons.notifications_none,
      _ => Icons.help_outline,
    };
  }
}

class _ItemTipoLista extends StatelessWidget {
  final TipoSos tipo;
  final Color cor;
  final VoidCallback onTap;

  const _ItemTipoLista({required this.tipo, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(tipo.icone, color: cor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tipo.label,
                style: const TextStyle(color: AppColors.textMain, fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right, color: cor.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STEP 2 — Confirmação e envio
// ============================================================================
class _StepEnvio extends StatefulWidget {
  final SosController controller;
  final TipoSos tipo;
  final ScrollController scrollController;
  final VoidCallback onBack;
  final ValueChanged<AlertaCriado> onEnviado;

  const _StepEnvio({
    required this.controller,
    required this.tipo,
    required this.scrollController,
    required this.onBack,
    required this.onEnviado,
  });

  @override
  State<_StepEnvio> createState() => _StepEnvioState();
}

class _StepEnvioState extends State<_StepEnvio> {
  late final TextEditingController _localCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _localCtrl = TextEditingController(text: widget.controller.localizacaoSugerida());
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        // Header com botão voltar
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
              onPressed: widget.onBack,
            ),
            const Expanded(
              child: Text(
                'Confirmar envio',
                style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textMuted),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Card do tipo seleccionado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.tipo.cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.tipo.cor.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.tipo.cor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.tipo.icone, color: widget.tipo.cor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tipo.label,
                      style: TextStyle(
                        color: widget.tipo.cor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gravidade: ${_gravidadeLabel(widget.tipo.gravidade)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Localização
        const Text(
          'Localização',
          style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _localCtrl,
          style: const TextStyle(color: AppColors.textMain, fontSize: 14),
          decoration: _decoration('Ex: Bloco A, 3º andar'),
        ),
        const SizedBox(height: 16),

        // Descrição opcional
        const Text(
          'Descrição (opcional)',
          style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descCtrl,
          style: const TextStyle(color: AppColors.textMain, fontSize: 14),
          maxLines: 3,
          decoration: _decoration('Pormenores adicionais...'),
        ),
        const SizedBox(height: 24),

        // === SECÇÃO FOTOS ===
        _SecaoFotos(controller: widget.controller, corTipo: widget.tipo.cor),
        const SizedBox(height: 24),

        // Aviso especial para críticos
        if (widget.tipo.ehCritico) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 0.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.danger, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Alerta crítico será enviado imediatamente. Em caso de emergência grave, contacte também o 113 (Polícia) ou 115 (Bombeiros).',
                    style: TextStyle(color: AppColors.textMain, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Botão enviar
        Obx(() => SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.controller.isEnviando.value ? null : _enviar,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.tipo.cor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: widget.controller.isEnviando.value
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.tipo.ehCritico ? 'ENVIAR ALERTA AGORA' : 'ENVIAR ALERTA',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ],
                  ),
          ),
        )),

        // Erro de envio
        Obx(() {
          final erro = widget.controller.erro.value;
          if (erro == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              erro,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _enviar() async {
    // Se não-crítico, mostra modal de confirmação primeiro
    if (!widget.tipo.ehCritico) {
      final confirmou = await _confirmar();
      if (!confirmou) return;
    }

    final alerta = await widget.controller.enviarAlerta(
      tipo: widget.tipo.key,
      localizacao: _localCtrl.text.trim().isEmpty ? null : _localCtrl.text.trim(),
      descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    if (alerta != null && mounted) {
      widget.onEnviado(alerta);
    }
  }

  Future<bool> _confirmar() async {
    if (!mounted) return false;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirmar envio?', style: TextStyle(color: AppColors.textMain)),
        content: Text(
          'O alerta "${widget.tipo.label}" será enviado à segurança e administração do condomínio.',
          style: const TextStyle(color: AppColors.textMain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.tipo.cor, foregroundColor: Colors.white),
            child: const Text('Sim, enviar'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  String _gravidadeLabel(GravidadeSos g) {
    return switch (g) {
      GravidadeSos.critico => 'CRÍTICO',
      GravidadeSos.alto => 'Alto',
      GravidadeSos.medio => 'Médio',
      GravidadeSos.baixo => 'Baixo',
    };
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.tipo.cor.withValues(alpha: 0.6), width: 1),
      ),
      contentPadding: const EdgeInsets.all(14),
    );
  }
}
// ============================================================================
// SECÇÃO FOTOS
// ============================================================================
class _SecaoFotos extends StatelessWidget {
  final SosController controller;
  final Color corTipo;

  const _SecaoFotos({required this.controller, required this.corTipo});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fotos = controller.fotos;
      final podeAdicionar = fotos.length < SosController.maxFotos;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.textMain),
              const SizedBox(width: 6),
              const Text(
                'Fotos (opcional)',
                style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${fotos.length}/${SosController.maxFotos}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Preview das fotos seleccionadas
          if (fotos.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _FotoPreview(
                  file: fotos[i],
                  onRemove: () => controller.removerFoto(i),
                ),
              ),
            ),

          if (fotos.isNotEmpty) const SizedBox(height: 10),

          // Botões para adicionar
          if (podeAdicionar)
            Row(
              children: [
                Expanded(
                  child: _BotaoFoto(
                    icone: Icons.camera_alt_outlined,
                    label: 'Câmara',
                    cor: corTipo,
                    onTap: () => controller.adicionarFotoCamera(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BotaoFoto(
                    icone: Icons.photo_library_outlined,
                    label: 'Galeria',
                    cor: corTipo,
                    onTap: () => controller.adicionarFotoGaleria(),
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }
}

class _FotoPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _FotoPreview({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotaoFoto extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color cor;
  final VoidCallback onTap;

  const _BotaoFoto({
    required this.icone,
    required this.label,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cor.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
