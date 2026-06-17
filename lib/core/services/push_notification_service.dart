import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'storage_service.dart';
import '../../features/avisos/views/aviso_detalhe_view.dart';
import '../../features/sos_guarda/views/sos_guarda_lista_view.dart';
import '../../features/sos_guarda/utils/sos_sirene.dart';

/// Serviço para gerir push notifications via Firebase Cloud Messaging.
class PushNotificationService extends GetxService {
  static PushNotificationService get to => Get.find();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  bool _localNotifPronto = false;

  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'ondaka_default',
    'Notificações ONDAKA',
    description: 'Avisos, pedidos e alertas do condomínio',
    importance: Importance.max,
  );

  /// Canal dedicado ao SOS — toca a sirene (res/raw/sirene_sos) com
  /// importância máxima, mesmo com a app em background/fechada.
  static const AndroidNotificationChannel _canalSos = AndroidNotificationChannel(
    'ondaka_sos',
    'Alertas SOS',
    description: 'Emergências SOS — sirene de alerta para guardas',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('sirene_sos'),
    playSound: true,
    enableVibration: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  @override
  void onInit() {
    super.onInit();
    _setup();
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotifPronto) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == 'sos') {
          SosSirene.instance.parar();
          Get.to(() => const SosGuardaListaView());
        }
      },
    );
    final androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_canal);
    await androidPlugin?.createNotificationChannel(_canalSos);
    _localNotifPronto = true;
  }

  void _mostrarNotificacaoLocal(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final ehSos = message.data['tipo']?.toString() == 'sos';
    final canal = ehSos ? _canalSos : _canal;
    _localNotif.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          canal.id,
          canal.name,
          channelDescription: canal.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: ehSos
              ? const RawResourceAndroidNotificationSound('sirene_sos')
              : null,
          category: ehSos ? AndroidNotificationCategory.alarm : null,
        ),
        iOS: DarwinNotificationDetails(
          sound: ehSos ? 'sirene_sos.mp3' : null,
        ),
      ),
      payload: message.data['tipo']?.toString(),
    );
    // SOS em foreground: além do toque do canal, arranca a sirene em loop
    // (silenciada no ecrã da lista SOS ou quando o alerta é resolvido).
    if (ehSos) {
      SosSirene.instance.tocar();
    }
  }

  Future<void> _setup() async {
    try {
      await _initLocalNotifications();
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
        _mostrarNotificacaoLocal(message);
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
    } else if (tipo == 'sos') {
      Get.to(() => const SosGuardaListaView());
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
    final ehSos = message.data['tipo']?.toString() == 'sos';
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: ehSos ? 30 : 10),
      icon: Icon(
        ehSos ? Icons.warning_amber_rounded : Icons.notifications_active,
        color: Colors.white,
      ),
      backgroundColor: ehSos ? const Color(0xEEB91C1C) : const Color(0xCC1F2937),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      isDismissible: true,
      shouldIconPulse: true,
      mainButton: ehSos
          ? TextButton(
              onPressed: () {
                Get.closeCurrentSnackbar();
                Get.to(() => const SosGuardaListaView());
              },
              child: const Text('Atender',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : TextButton(
              onPressed: () => Get.closeCurrentSnackbar(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}
