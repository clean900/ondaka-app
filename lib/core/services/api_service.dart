import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

/// Cliente HTTP centralizado para falar com a API ONDAKA.
///
/// Uso:
/// ```dart
/// final api = Get.find<ApiService>();
/// final response = await api.dio.get('/user');
/// ```
///
/// Features:
/// - Token Bearer injectado automaticamente (interceptor)
/// - Headers padrão (Accept, Content-Type JSON)
/// - Logging em debug mode
/// - 401 → força logout
class ApiService extends GetxService {
  static ApiService get to => Get.find();

  late final Dio dio;

  @override
  void onInit() {
    super.onInit();
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
        // Aceita 2xx como sucesso; 4xx/5xx → DioException
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // --- 1) Autenticação: injecta Bearer token se existir ---
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.to.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // 401 → sessão expirada: limpa storage e envia para /login
          if (error.response?.statusCode == 401) {
            await StorageService.to.clearAll();
            // Navegação só se ainda estiver dentro da app
            if (Get.currentRoute != '/login') {
              Get.offAllNamed('/login');
            }
          }
          return handler.next(error);
        },
      ),
    );

    // --- 2) Logging em debug mode ---
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false, // não logar token em produção
          responseHeader: false,
          error: true,
        ),
      );
    }
  }

  /// Helper para testar conectividade com a API (debug).
  Future<bool> ping() async {
    try {
      final response = await dio.get('/user');
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }
}
