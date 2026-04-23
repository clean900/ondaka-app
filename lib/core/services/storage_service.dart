import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Serviço centralizado para armazenamento seguro.
///
/// Usa [FlutterSecureStorage] que encripta nativamente:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences / Keystore
/// - Web: localStorage (menos seguro, mas aceitável para tokens de curta duração)
///
/// Regra de ouro: **usar isto só para dados sensíveis** (tokens, PIN, credenciais).
/// Para preferências normais (tema, idioma), usar SharedPreferences.
class StorageService extends GetxService {
  static StorageService get to => Get.find();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // === Chaves (constantes para evitar typos) ===
  static const _keyAuthToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';
  static const _keyUserRole = 'user_role';
  static const _keyEmpresaId = 'empresa_gestora_id';

  // === Token ===

  Future<String?> getAuthToken() => _storage.read(key: _keyAuthToken);

  Future<void> saveAuthToken(String token) =>
      _storage.write(key: _keyAuthToken, value: token);

  Future<void> deleteAuthToken() => _storage.delete(key: _keyAuthToken);

  // === Dados do user autenticado ===

  Future<void> saveUser({
    required int id,
    required String email,
    required String name,
    required String role,
    required int empresaGestoraId,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: id.toString()),
      _storage.write(key: _keyUserEmail, value: email),
      _storage.write(key: _keyUserName, value: name),
      _storage.write(key: _keyUserRole, value: role),
      _storage.write(key: _keyEmpresaId, value: empresaGestoraId.toString()),
    ]);
  }

  Future<Map<String, String?>> getUser() async {
    final results = await Future.wait([
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserEmail),
      _storage.read(key: _keyUserName),
      _storage.read(key: _keyUserRole),
      _storage.read(key: _keyEmpresaId),
    ]);
    return {
      'id': results[0],
      'email': results[1],
      'name': results[2],
      'role': results[3],
      'empresa_gestora_id': results[4],
    };
  }

  // === Limpeza global (logout) ===

  Future<void> clearAll() => _storage.deleteAll();

  /// Verifica rapidamente se há sessão activa (token presente).
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
