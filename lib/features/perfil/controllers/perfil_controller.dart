import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../models/perfil.dart';
import '../repositories/perfil_repository.dart';

/// Controller do ecra de perfil.
/// - Carrega o perfil ao abrir
/// - Submete alteracoes
/// - Muda password
class PerfilController extends GetxController {
  final PerfilRepository _repo;

  PerfilController({PerfilRepository? repo}) : _repo = repo ?? PerfilRepository();

  final perfil = Rxn<Perfil>();
  final isLoading = false.obs;
  final isSubmittingPerfil = false.obs;
  final isSubmittingPassword = false.obs;
  final erroGeral = RxnString();

  // Form errors (por campo)
  final erros = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erroGeral.value = null;
    try {
      perfil.value = await _repo.obter();
    } on DioException catch (e) {
      erroGeral.value = _msgDio(e);
    } catch (e) {
      erroGeral.value = 'Erro inesperado: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Actualiza dados do perfil. Devolve true em sucesso.
  Future<bool> actualizarPerfil({
    required String name,
    required String email,
    String? telefone,
    String? locale,
  }) async {
    if (isSubmittingPerfil.value) return false;
    isSubmittingPerfil.value = true;
    erros.clear();

    try {
      final novoPerfil = await _repo.actualizar(
        name: name,
        email: email,
        telefone: telefone,
        locale: locale,
      );
      perfil.value = novoPerfil;

      // Sincronizar AuthService.fetchUser para actualizar tambem o storage
      await AuthService.to.fetchUser();

      Get.snackbar(
        'Perfil actualizado',
        'As suas alteracoes foram guardadas.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on DioException catch (e) {
      _tratarErroValidacao(e);
      return false;
    } catch (e) {
      Get.snackbar('Erro', 'Erro inesperado.', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSubmittingPerfil.value = false;
    }
  }

  /// Muda password. Devolve true em sucesso.
  Future<bool> mudarPassword({
    required String passwordActual,
    required String passwordNova,
    required String passwordNovaConfirmation,
  }) async {
    if (isSubmittingPassword.value) return false;
    isSubmittingPassword.value = true;
    erros.clear();

    try {
      final msg = await _repo.mudarPassword(
        passwordActual: passwordActual,
        passwordNova: passwordNova,
        passwordNovaConfirmation: passwordNovaConfirmation,
      );

      Get.snackbar(
        'Sucesso',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Re-carregar perfil para actualizar must_change_password
      await carregar();
      return true;
    } on DioException catch (e) {
      _tratarErroValidacao(e);
      return false;
    } catch (e) {
      Get.snackbar('Erro', 'Erro inesperado.', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSubmittingPassword.value = false;
    }
  }

  void _tratarErroValidacao(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // Mensagem geral (ex: "A password actual está incorrecta")
    if (status == 422 && data is Map && data['message'] is String) {
      // Se houver errors detalhados por campo, popular o map
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            erros[key.toString()] = value.first.toString();
          }
        });
      }

      Get.snackbar(
        'Erro',
        data['message'] as String,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Erro',
        _msgDio(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _msgDio(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessao expirada.';
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Erro ao comunicar com o servidor.';
  }
}
