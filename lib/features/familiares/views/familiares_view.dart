import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/familiar_controller.dart';
import '../models/familiar.dart';

class FamiliaresView extends StatelessWidget {
  const FamiliaresView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(FamiliarController());
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Membros da família'),
        backgroundColor: AppColors.bgDark,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.bgDark,
        onPressed: () => _formFamiliar(context, c),
        icon: const Icon(Icons.person_add),
        label: const Text('Adicionar'),
      ),
      body: Obx(() {
        if (c.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.familiares.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.family_restroom, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('Ainda não adicionou familiares.',
                      style: TextStyle(color: AppColors.textMain, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Adicione membros da família para acederem à app com acesso limitado. Eles não veem valores nem fazem pagamentos.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.familiares.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _cartaoFamiliar(context, c, c.familiares[i]),
        );
      }),
    );
  }

  Widget _cartaoFamiliar(BuildContext context, FamiliarController c, Familiar f) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                child: Text(f.nome.isNotEmpty ? f.nome[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.nome, style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600, fontSize: 15)),
                    if (f.parentesco != null && f.parentesco!.isNotEmpty)
                      Text(f.parentesco!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    if (f.telefone != null) Text(f.telefone!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (!f.ativo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Inativo', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: f.acessos.map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(kAcessoLabels[a] ?? a, style: const TextStyle(color: AppColors.cyanSoft, fontSize: 11)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _formAcessos(context, c, f),
                icon: const Icon(Icons.tune, size: 16, color: AppColors.cyan),
                label: const Text('Acessos', style: TextStyle(color: AppColors.cyan, fontSize: 13)),
              ),
              TextButton.icon(
                onPressed: () => c.alternarAtivo(f),
                icon: Icon(f.ativo ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16, color: AppColors.textMuted),
                label: Text(f.ativo ? 'Suspender' : 'Ativar', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _confirmarRemover(context, c, f),
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _formFamiliar(BuildContext context, FamiliarController c) {
    final nome = TextEditingController();
    final parentesco = TextEditingController();
    final telefone = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final selecionados = <String>{'avisos', 'portaria', 'sos'};

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adicionar familiar', style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _campo(nome, 'Nome', Icons.person_outline),
                const SizedBox(height: 10),
                _campo(parentesco, 'Parentesco (ex.: Cônjuge, Filho)', Icons.family_restroom),
                const SizedBox(height: 10),
                _campo(telefone, 'Telemóvel', Icons.phone_outlined, tipo: TextInputType.phone),
                const SizedBox(height: 10),
                _campo(email, 'Email (opcional)', Icons.email_outlined, tipo: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _campo(password, 'Palavra-passe (mín. 6)', Icons.lock_outline, obscure: true),
                const SizedBox(height: 16),
                const Text('O que pode aceder', style: TextStyle(color: AppColors.cyanSoft, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('O familiar nunca vê valores nem faz pagamentos.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                ...c.acessosDisponiveis.map((a) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppColors.cyan,
                  title: Text(kAcessoLabels[a] ?? a, style: const TextStyle(color: AppColors.textMain, fontSize: 14)),
                  value: selecionados.contains(a),
                  onChanged: (v) => setState(() => v == true ? selecionados.add(a) : selecionados.remove(a)),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: c.aProcessar.value ? null : () async {
                      if (nome.text.trim().isEmpty || telefone.text.trim().isEmpty || password.text.length < 6) {
                        Get.snackbar('Atenção', 'Preencha nome, telemóvel e palavra-passe (mín. 6).',
                            backgroundColor: AppColors.surface, colorText: AppColors.textMain);
                        return;
                      }
                      final ok = await c.criar(
                        nome: nome.text.trim(),
                        parentesco: parentesco.text.trim().isEmpty ? null : parentesco.text.trim(),
                        telefone: telefone.text.trim(),
                        email: email.text.trim().isEmpty ? null : email.text.trim(),
                        password: password.text,
                        acessos: selecionados.toList(),
                      );
                      if (ok) Get.back();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: AppColors.bgDark),
                    child: c.aProcessar.value ? const Text('A guardar...') : const Text('Adicionar familiar'),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _formAcessos(BuildContext context, FamiliarController c, Familiar f) {
    final selecionados = f.acessos.toSet();
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acessos de ${f.nome}', style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...c.acessosDisponiveis.map((a) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppColors.cyan,
                  title: Text(kAcessoLabels[a] ?? a, style: const TextStyle(color: AppColors.textMain, fontSize: 14)),
                  value: selecionados.contains(a),
                  onChanged: (v) => setState(() => v == true ? selecionados.add(a) : selecionados.remove(a)),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await c.atualizarAcessos(f.id, selecionados.toList());
                      if (ok) Get.back();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: AppColors.bgDark),
                    child: const Text('Guardar acessos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmarRemover(BuildContext context, FamiliarController c, Familiar f) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remover familiar', style: TextStyle(color: AppColors.textMain)),
        content: Text('Remover ${f.nome}? A conta de acesso será desativada.', style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              Get.back();
              await c.remover(f.id);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, TextInputType? tipo}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: tipo,
      style: const TextStyle(color: AppColors.textMain),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
