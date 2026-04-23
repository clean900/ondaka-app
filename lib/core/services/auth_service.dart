import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Resultado de uma tentativa de autenticação.
/// Padrão "sealed class" para forçar handling explícito de cada caso.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  final String token;
  final Map<String, dynamic> user;
  const AuthSuccess({required this.token, required this.user});
}

class AuthFailure extends AuthResult {
  final String message;
  final int? statusCode;
  const AuthFailure({required this.message, this.statusCode});
}

/// Serviço de autenticação.
///
/// Camada fina sobre [ApiService] + [StorageService] que expõe operações
/// de negócio: login, logout, fetchUser. Os controllers (ex: LoginController)
/// chamam estes métodos e reagem ao [AuthResult].
class AuthService extends GetxService {
  static AuthService get to => Get.find();

  ApiService get _api => ApiService.to;
  StorageService get _storage => StorageService.to;

  /// Login com email + password.
  ///
  /// Em caso de sucesso, guarda o token e os dados do user no storage seguro.
  Future<AuthResult> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    try {
      final response = await _api.dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          if (deviceName != null) 'device_name': deviceName,
        },
      );

      final token = response.data['token'] as String;
      final user = Map<String, dynamic>.from(response.data['user']);

      // Guardar token
      await _storage.saveAuthToken(token);

      // Guardar dados do user
      final roles = user['roles'] as List;
      await _storage.saveUser(
        id: user['id'] as int,
        email: user['email'] as String,
        name: user['name'] as String,
        role: roles.isNotEmpty ? roles.first as String : '',
        empresaGestoraId: user['empresa_gestora_id'] as int,
      );

      return AuthSuccess(token: token, user: user);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthFailure(message: 'Erro inesperado: $e');
    }
  }

  /// Logout — revoga token no servidor e limpa storage local.
  Future<void> logout() async {
    try {
      await _api.dio.post('/logout');
    } on DioException catch (_) {
      // Mesmo que o servidor falhe, limpamos storage local.
    } finally {
      await _storage.clearAll();
    }
  }

  /// Obtém dados actualizados do user autenticado.
  /// Útil para validar que o token ainda é válido.
  Future<Map<String, dynamic>?> fetchUser() async {
    try {
      final response = await _api.dio.get('/user');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (_) {
      return null;
    }
  }

  // === Helpers ===

  AuthFailure _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;

    // 422 = validação Laravel (credenciais inválidas, etc.)
    if (statusCode == 422) {
      final errors = e.response?.data['errors'] as Map?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return AuthFailure(message: firstError.first.toString(), statusCode: 422);
        }
      }
      return const AuthFailure(message: 'Credenciais inválidas.', statusCode: 422);
    }

    // 401 = não autenticado (não devia acontecer no login, mas por segurança)
    if (statusCode == 401) {
      return const AuthFailure(message: 'Credenciais inválidas.', statusCode: 401);
    }

    // Timeout
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const AuthFailure(message: 'Ligação lenta. Tenta de novo.');
    }

    // Sem internet / servidor inacessível
    if (e.type == DioExceptionType.connectionError) {
      return const AuthFailure(message: 'Sem ligação ao servidor. Verifica a tua internet.');
    }

    // Outros
    return AuthFailure(
      message: 'Erro de servidor (${statusCode ?? 'sem código'}).',
      statusCode: statusCode,
    );
  }
}
