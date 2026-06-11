import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/perfil_controller.dart';
import '../models/perfil.dart';
import '../repositories/perfil_repository.dart';

/// Ecra do perfil do user logado.
/// Tem 2 tabs: Dados pessoais + Alterar password.
class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PerfilController controller;

  // Form perfil
  final _formPerfil = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefoneCtrl;
  String _locale = 'pt_AO';

  // Form password
  final _formPassword = GlobalKey<FormState>();
  final _pwActualCtrl = TextEditingController();
  final _pwNovaCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _showActual = false;
  bool _showNova = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PerfilController());
    _tabController = TabController(length: 2, vsync: this);

    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _telefoneCtrl = TextEditingController();

    // Quando o perfil carregar, preenche os campos
    ever<Perfil?>(controller.perfil, (p) {
      if (p != null) {
        _nameCtrl.text = p.name;
        _emailCtrl.text = p.email;
        _telefoneCtrl.text = p.telefone ?? '';
        setState(() => _locale = p.locale);

        // Se must_change_password, vai directo para a tab password
        if (p.mustChangePassword) {
          _tabController.animateTo(1);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _pwActualCtrl.dispose();
    _pwNovaCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submeterPerfil() async {
    if (!_formPerfil.currentState!.validate()) return;
    await controller.actualizarPerfil(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telefone: _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      locale: _locale,
    );
  }

  Future<void> _submeterPassword() async {
    if (!_formPassword.currentState!.validate()) return;

    final ok = await controller.mudarPassword(
      passwordActual: _pwActualCtrl.text,
      passwordNova: _pwNovaCtrl.text,
      passwordNovaConfirmation: _pwConfirmCtrl.text,
    );

    if (ok) {
      _pwActualCtrl.clear();
      _pwNovaCtrl.clear();
      _pwConfirmCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Dados'),
            Tab(icon: Icon(Icons.lock_outline, size: 18), text: 'Password'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.perfil.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erroGeral.value != null && controller.perfil.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                  const SizedBox(height: 12),
                  Text(controller.erroGeral.value!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMain)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: controller.carregar,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.cyan),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
          );
        }

        final perfil = controller.perfil.value;
        if (perfil == null) return const SizedBox.shrink();

        return TabBarView(
          controller: _tabController,
          children: [
            _buildTabPerfil(perfil),
            _buildTabPassword(perfil),
          ],
        );
      }),
    );
  }

  Widget _buildTabPerfil(Perfil perfil) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar + nome no topo
        _AvatarCard(perfil: perfil),
        const SizedBox(height: 24),

        Form(
          key: _formPerfil,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Nome completo *'),
              TextFormField(
                controller: _nameCtrl,
                decoration: _decoration(hint: 'O seu nome'),
                style: const TextStyle(color: AppColors.textMain),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Minimo 2 caracteres' : null,
              ),
              const SizedBox(height: 16),

              const _Label('Email *'),
              TextFormField(
                controller: _emailCtrl,
                decoration: _decoration(hint: 'nome@exemplo.com'),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textMain),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email obrigatorio';
                  if (!v.contains('@')) return 'Email invalido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const _Label('Telefone'),
              TextFormField(
                controller: _telefoneCtrl,
                decoration: _decoration(hint: '+244 9XX XXX XXX'),
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textMain),
              ),
              const SizedBox(height: 16),

              const _Label('Idioma'),
              DropdownButtonFormField<String>(
                initialValue: _locale,
                decoration: _decoration(),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textMain),
                items: const [
                  DropdownMenuItem(value: 'pt_AO', child: Text('Portugues (Angola)')),
                  DropdownMenuItem(value: 'pt_PT', child: Text('Portugues (Portugal)')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _locale = v);
                },
              ),
              const SizedBox(height: 24),

              Obx(() => FilledButton.icon(
                onPressed: controller.isSubmittingPerfil.value ? null : _submeterPerfil,
                icon: controller.isSubmittingPerfil.value
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(controller.isSubmittingPerfil.value ? 'A guardar...' : 'Guardar alteracoes'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              )),

              const SizedBox(height: 32),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              const Text(
                'Zona de perigo',
                style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _confirmarApagarConta,
                icon: const Icon(Icons.delete_forever, color: AppColors.danger),
                label: const Text('Apagar a minha conta', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmarApagarConta() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Apagar conta?', style: TextStyle(color: AppColors.textMain)),
        content: const Text(
          'Esta acção marca a sua conta para eliminação. Vai perder o acesso à app e aos seus dados.\n\n'
          'Tem 30 dias para recuperar a conta contactando o suporte. Após esse prazo, a eliminação é definitiva.\n\n'
          'Se for titular, os membros da sua família também perdem o acesso.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _apagarConta();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Apagar definitivamente'),
          ),
        ],
      ),
    );
  }

  Future<void> _apagarConta() async {
    try {
      final msg = await PerfilRepository().apagarConta();
      await AuthService.to.logout();
      await StorageService.to.clearAll();
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar('Conta apagada', msg, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível apagar a conta. Tente novamente.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _buildTabPassword(Perfil perfil) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (perfil.mustChangePassword) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tem de alterar a sua password antes de continuar.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Form(
          key: _formPassword,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Password actual *'),
              TextFormField(
                controller: _pwActualCtrl,
                obscureText: !_showActual,
                decoration: _decoration(
                  hint: 'Password actual',
                  suffix: IconButton(
                    icon: Icon(_showActual ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () => setState(() => _showActual = !_showActual),
                  ),
                ),
                style: const TextStyle(color: AppColors.textMain),
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatorio' : null,
              ),
              const SizedBox(height: 16),

              const _Label('Nova password *'),
              TextFormField(
                controller: _pwNovaCtrl,
                obscureText: !_showNova,
                decoration: _decoration(
                  hint: 'Minimo 8 caracteres',
                  suffix: IconButton(
                    icon: Icon(_showNova ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () => setState(() => _showNova = !_showNova),
                  ),
                ),
                style: const TextStyle(color: AppColors.textMain),
                validator: (v) {
                  if (v == null || v.length < 8) return 'Minimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const _Label('Confirmar nova password *'),
              TextFormField(
                controller: _pwConfirmCtrl,
                obscureText: !_showConfirm,
                decoration: _decoration(
                  hint: 'Repete a nova password',
                  suffix: IconButton(
                    icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                style: const TextStyle(color: AppColors.textMain),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatorio';
                  if (v != _pwNovaCtrl.text) return 'As passwords nao coincidem';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Obx(() => FilledButton.icon(
                onPressed: controller.isSubmittingPassword.value ? null : _submeterPassword,
                icon: controller.isSubmittingPassword.value
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_outline),
                label: Text(controller.isSubmittingPassword.value ? 'A actualizar...' : 'Alterar password'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final Perfil perfil;
  const _AvatarCard({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              perfil.iniciais,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfil.name,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  perfil.email,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (perfil.roles.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: perfil.roles
                        .map((r) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                r,
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
