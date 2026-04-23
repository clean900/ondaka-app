import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/login_controller.dart';

/// Ecrã de login ONDAKA.
///
/// Campos: email + password.
/// Ao autenticar com sucesso, navega para /home.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Regista o controller só quando este ecrã existe (lazy put)
    final c = Get.put(LoginController());

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: c.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === Logo ONDAKA ===
                    _buildLogo(),
                    const SizedBox(height: 48),

                    // === Título ===
                    Text(
                      'Bem-vindo',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entra para continuar',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // === Campo Email ===
                    TextFormField(
                      controller: c.emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: c.validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'exemplo@ondaka.ao',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // === Campo Password ===
                    Obx(() => TextFormField(
                          controller: c.passwordController,
                          obscureText: !c.showPassword.value,
                          textInputAction: TextInputAction.done,
                          validator: c.validatePassword,
                          onFieldSubmitted: (_) => c.submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                c.showPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: c.togglePasswordVisibility,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )),
                    const SizedBox(height: 24),

                    // === Mensagem de erro (se houver) ===
                    Obx(() {
                      final err = c.errorMessage.value;
                      if (err == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.dangerSoft, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                err,
                                style: const TextStyle(
                                  color: AppColors.dangerSoft,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // === Botão Entrar ===
                    Obx(() => ElevatedButton(
                          onPressed: c.isLoading.value ? null : c.submit,
                          child: c.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF001218),
                                  ),
                                )
                              : const Text('ENTRAR'),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.4),
            blurRadius: 30,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'O',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF001218),
          ),
        ),
      ),
    );
  }
}
