import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/autorizados_controller.dart';
import '../models/fraccao_autorizado.dart';

/// Ecrã de gestão de pessoas autorizadas a levantar encomendas em meu nome.
class AutorizadosView extends StatelessWidget {
  const AutorizadosView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AutorizadosController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.autorizados.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.erro.value != null && controller.autorizados.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text(controller.erro.value!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.carregar,
          child: CustomScrollView(
            slivers: [
              // Info no topo
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Estas pessoas podem levantar encomendas em teu nome na portaria.',
                          style: TextStyle(
                              color: AppColors.cyanSoft, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista
              if (controller.autorizados.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline,
                              color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhuma pessoa autorizada',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adiciona familiares ou empregadas que podem levantar encomendas por ti.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  sliver: SliverList.separated(
                    itemCount: controller.autorizados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final a = controller.autorizados[i];
                      return _AutorizadoCard(
                        autorizado: a,
                        isApagando: controller.isApagando(a.id),
                        onApagar: () => _confirmarApagar(context, controller, a),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormAdicionar(context),
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text('Adicionar'),
      ),
    );
  }

  void _confirmarApagar(BuildContext context, AutorizadosController controller,
      FraccaoAutorizado a) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remover pessoa autorizada?'),
        content: Text(
          'Tem a certeza que quer remover ${a.nomeCompleto}?\n\nEsta pessoa deixará de poder levantar encomendas em teu nome.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Não')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.apagar(a.id);
            },
            child: const Text('Sim, remover'),
          ),
        ],
      ),
    );
  }

  void _abrirFormAdicionar(BuildContext context) {
    Get.bottomSheet(
      const _FormAdicionarAutorizado(),
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

class _AutorizadoCard extends StatelessWidget {
  final FraccaoAutorizado autorizado;
  final bool isApagando;
  final VoidCallback onApagar;

  const _AutorizadoCard({
    required this.autorizado,
    required this.isApagando,
    required this.onApagar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_outline,
                  color: AppColors.purple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    autorizado.nomeCompleto,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    autorizado.relacaoLabel,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (autorizado.telefone != null &&
                      autorizado.telefone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          autorizado.telefone!,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: isApagando ? null : onApagar,
              icon: isApagando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }
}

class _FormAdicionarAutorizado extends StatefulWidget {
  const _FormAdicionarAutorizado();

  @override
  State<_FormAdicionarAutorizado> createState() =>
      _FormAdicionarAutorizadoState();
}

class _FormAdicionarAutorizadoState extends State<_FormAdicionarAutorizado> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _biController = TextEditingController();
  String _relacao = 'familiar';
  bool _submetendo = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _biController.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    final nome = _nomeController.text.trim();
    if (nome.length < 2) {
      Get.snackbar('Erro', 'Nome inválido.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _submetendo = true);
    final ok = await Get.find<AutorizadosController>().criar(
      nomeCompleto: nome,
      relacao: _relacao,
      biPassport: _biController.text.trim().isEmpty
          ? null
          : _biController.text.trim(),
      telefone: _telefoneController.text.trim().isEmpty
          ? null
          : _telefoneController.text.trim(),
    );
    setState(() => _submetendo = false);

    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Nova pessoa autorizada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            const Text('Nome completo *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(hintText: 'Ex: Maria Silva'),
              maxLength: 255,
            ),
            const SizedBox(height: 8),

            const Text('Relação *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _relacao,
              items: const [
                DropdownMenuItem(value: 'conjuge', child: Text('Cônjuge')),
                DropdownMenuItem(value: 'filho', child: Text('Filho/a')),
                DropdownMenuItem(
                    value: 'empregada', child: Text('Empregada')),
                DropdownMenuItem(value: 'familiar', child: Text('Familiar')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _relacao = v);
              },
            ),
            const SizedBox(height: 16),

            const Text('Telefone (opcional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+244 9XX XXX XXX'),
              maxLength: 30,
            ),
            const SizedBox(height: 8),

            const Text('BI / Passaporte (opcional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _biController,
              decoration: const InputDecoration(hintText: 'Número do documento'),
              maxLength: 50,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submetendo ? null : _submeter,
                icon: _submetendo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_submetendo ? 'A guardar...' : 'Adicionar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
