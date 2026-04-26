import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'storage_service.dart';

/// Serviço para gerir push notifications via Firebase Cloud Messaging.
///
/// Responsabilidades:
///   - Pedir permissão de notificações ao utilizador
///   - Obter token FCM do dispositivo
///   - Registar token no backend (associado ao user logado)
///   - Receber notificações em foreground / background
class PushNotificationService extends GetxService {
  static PushNotificationService get to => Get.find();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Token FCM actual deste dispositivo (cacheado).
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  @override
  void onInit() {
    super.onInit();
    _setup();
  }

  Future<void> _setup() async {
    try {
      // 1. Pedir permissão (no Android 13+ e iOS é obrigatório)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('[Push] Utilizador rejeitou notificações.');
        return;
      }

      // 2. Obter token FCM
      _fcmToken = await _messaging.getToken();
      debugPrint('[Push] FCM Token: $_fcmToken');

      // 3. Registar token no backend (se user já está logado)
      if (_fcmToken != null && (await StorageService.to.getAuthToken()) != null) {
        await _registarTokenNoBackend(_fcmToken!);
      }

      // 4. Listener para refresh do token
      _messaging.onTokenRefresh.listen((novoToken) async {
        _fcmToken = novoToken;
        debugPrint('[Push] Token refreshed: $novoToken');
        if ((await StorageService.to.getAuthToken()) != null) {
          await _registarTokenNoBackend(novoToken);
        }
      });

      // 5. Handler para mensagens em foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[Push] Mensagem recebida (foreground): ${message.notification?.title}');
        _mostrarSnackbar(message);
      });

      // 6. Handler para tap na notificação (app em background → foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[Push] App aberta via notificação: ${message.data}');
        // TODO: Navegar para detalhe baseado em message.data['route']
      });
    } catch (e) {
      debugPrint('[Push] Erro setup: $e');
    }
  }

  /// Regista o token FCM no backend para o user actualmente logado.
  Future<void> _registarTokenNoBackend(String token) async {
    try {
      await ApiService.to.dio.post(
        '/devices/register-fcm-token',
        data: {
          'token': token,
          'platform': 'android',
        },
      );
      debugPrint('[Push] Token registado no backend.');
    } on DioException catch (e) {
      debugPrint('[Push] Erro a registar token: ${e.message}');
    }
  }

  /// Chamar APÓS login para registar o token (se ainda não foi registado).
  Future<void> registarApoUsLogin() async {
    if (_fcmToken != null) {
      await _registarTokenNoBackend(_fcmToken!);
    }
  }

  void _mostrarSnackbar(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notificação';
    final body = message.notification?.body ?? '';
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 10),
      icon: const Icon(Icons.notifications_active, color: Colors.white),
      backgroundColor: const Color(0xCC1F2937),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      isDismissible: true,
      shouldIconPulse: true,
      mainButton: TextButton(
        onPressed: () => Get.closeCurrentSnackbar(),
        child: const Text('OK', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
