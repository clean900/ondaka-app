import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';

/// Controller do ecrã de login.
///
/// Responsável por:
/// - Gerir estado dos campos (email, password)
/// - Validar input do utilizador
/// - Chamar AuthService
/// - Navegar em caso de sucesso
/// - Mostrar erros amigáveis
class LoginController extends GetxController {
  final AuthService _auth = AuthService.to;

  // Controllers dos TextFormField (gerem o texto)
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Estado reactivo (.obs)
  final isLoading = false.obs;
  final showPassword = false.obs;
  final errorMessage = RxnString(); // pode ser null

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email obrigatório';
    }
    final emailRegex = RegExp(r'^[\w.\-]+@[\w.\-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password obrigatória';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  Future<void> submit() async {
    // Limpa erro anterior
    errorMessage.value = null;

    // Valida o formulário
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    isLoading.value = true;

    final result = await _auth.login(
      email: emailController.text.trim(),
      password: passwordController.text,
      deviceName: 'mobile-flutter',
    );

    isLoading.value = false;

    switch (result) {
      case AuthSuccess():
        // Login OK → navega para home (limpa stack de navegação)
        Get.offAllNamed(AppRoutes.home);
      case AuthFailure(message: final msg):
        errorMessage.value = msg;
    }
  }
}
