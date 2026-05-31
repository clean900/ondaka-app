import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'storage_service.dart';
import '../../features/avisos/views/aviso_detalhe_view.dart';

/// Serviço para gerir push notifications via Firebase Cloud Messaging.
class PushNotificationService extends GetxService {
  static PushNotificationService get to => Get.find();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  @override
  void onInit() {
    super.onInit();
    _setup();
  }

  Future<void> _setup() async {
    try {
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

      _fcmToken = await _messaging.getToken();
      debugPrint('[Push] FCM Token: $_fcmToken');

      if (_fcmToken != null && (await StorageService.to.getAuthToken()) != null) {
        await _registarTokenNoBackend(_fcmToken!);
      }

      _messaging.onTokenRefresh.listen((novoToken) async {
        _fcmToken = novoToken;
        if ((await StorageService.to.getAuthToken()) != null) {
          await _registarTokenNoBackend(novoToken);
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[Push] Mensagem recebida (foreground): ${message.notification?.title}');
        _mostrarSnackbar(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[Push] App aberta via notificação: ${message.data}');
        _abrirDestino(message);
      });
    } catch (e) {
      debugPrint('[Push] Erro setup: $e');
    }
  }

  void _abrirDestino(RemoteMessage message) {
    final data = message.data;
    final tipo = data['tipo']?.toString();
    final avisoId = int.tryParse(data['aviso_id']?.toString() ?? '');
    if (tipo == 'aviso_publicado' && avisoId != null) {
      Get.to(() => AvisoDetalheView(avisoId: avisoId));
    }
  }

  Future<void> _registarTokenNoBackend(String token) async {
    try {
      await ApiService.to.dio.post(
        '/devices/register-fcm-token',
        data: {'token': token, 'platform': 'android'},
      );
      debugPrint('[Push] Token registado no backend.');
    } on DioException catch (e) {
      debugPrint('[Push] Erro a registar token: ${e.message}');
    }
  }

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
