import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/perfil.dart';

/// Repository para o perfil do user logado.
/// Usa os endpoints /api/user (GET), /api/me/profile (PATCH), /api/me/password (PATCH).
class PerfilRepository {
  final Dio _dio;

  PerfilRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// GET /api/user — obtem dados frescos do user logado.
  Future<Perfil> obter() async {
    final response = await _dio.get('/user');
    return Perfil.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /api/me/profile — actualiza dados básicos.
  /// Devolve o user actualizado.
  Future<Perfil> actualizar({
    String? name,
    String? email,
    String? telefone,
    String? locale,
  }) async {
    final response = await _dio.patch(
      '/me/profile',
      data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (telefone != null) 'telefone': telefone,
        if (locale != null) 'locale': locale,
      },
    );

    // O endpoint retorna {message, user: {...}}
    final userData = response.data['user'] as Map<String, dynamic>;
    return Perfil.fromJson(userData);
  }

  /// PATCH /api/me/password — muda password.
  /// Retorna a mensagem de sucesso ou lanca excepcao.
  Future<String> mudarPassword({
    required String passwordActual,
    required String passwordNova,
    required String passwordNovaConfirmation,
  }) async {
    final response = await _dio.patch(
      '/me/password',
      data: {
        'password_actual': passwordActual,
        'password_nova': passwordNova,
        'password_nova_confirmation': passwordNovaConfirmation,
      },
    );

    return response.data['message'] as String? ?? 'Password actualizada.';
  }

  /// Apaga (soft-delete) a conta do utilizador autenticado.
  Future<String> apagarConta() async {
    final response = await _dio.delete('/me/conta');
    return response.data['message'] as String? ?? 'Conta apagada.';
  }
}
