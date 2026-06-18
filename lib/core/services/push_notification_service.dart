import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'storage_service.dart';
import '../../features/avisos/views/aviso_detalhe_view.dart';
import '../../features/sos_guarda/views/sos_alarme_view.dart';
import '../../features/sos_guarda/utils/sos_sirene.dart';

/// Canal SOS — partilhado entre o serviço e o background handler.
/// Importância máxima + som de sirene (res/raw/sirene_sos). Tem de existir no
/// device para o som tocar quando a notificação chega em background/fechada.
const AndroidNotificationChannel canalSos = AndroidNotificationChannel(
  'ondaka_sos',
  'Alertas SOS',
  description: 'Emergências SOS — sirene de alerta para guardas',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('sirene_sos'),
  playSound: true,
  enableVibration: true,
);

/// Handler de mensagens FCM em BACKGROUND/app fechada (isolate separado).
/// Para SOS (data-only), constrói uma notificação full-screen que acorda o
/// ecrã e lança o alarme vermelho mesmo com a app fechada. Tem de ser uma
/// função top-level com @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> sosFirebaseBackgroundHandler(RemoteMessage message) async {
  if (message.data['tipo']?.toString() != 'sos') return;
  await Firebase.initializeApp();

  final fln = FlutterLocalNotificationsPlugin();
  await fln.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await fln
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(canalSos);

  final titulo = message.data['titulo']?.toString() ?? '🚨 SOS';
  final corpo = message.data['corpo']?.toString() ?? 'Emergência recebida';

  await fln.show(
    20260618,
    titulo,
    corpo,
    NotificationDetails(
      android: AndroidNotificationDetails(
        canalSos.id,
        canalSos.name,
        channelDescription: canalSos.description,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        sound: const RawResourceAndroidNotificationSound('sirene_sos'),
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

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
      onDidReceiveNotificationResponse: (resp) => _abrirAlarmeDePayload(resp.payload),
    );
    final androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_canal);
    await androidPlugin?.createNotificationChannel(canalSos);
    _localNotifPronto = true;
  }

  /// Abre o ecrã de alarme SOS a partir dos dados do push.
  void _abrirAlarmeSos(Map<String, dynamic> data) {
    final titulo = data['titulo']?.toString() ?? '🚨 SOS';
    final corpo = data['corpo']?.toString() ?? '';
    final local = corpo.toLowerCase().startsWith('local:')
        ? corpo.substring(6).trim()
        : null;
    final sosId = int.tryParse(data['sos_id']?.toString() ?? '');
    SosSirene.instance.tocar();
    Get.to(() => SosAlarmeView(tipoLabel: titulo, local: local, sosId: sosId));
  }

  /// Abre o alarme a partir do payload (JSON) de uma notificação tocada/lançada.
  void _abrirAlarmeDePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['tipo']?.toString() == 'sos') {
        _abrirAlarmeSos(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // payload antigo (string simples) — ignora.
    }
  }

  void _mostrarNotificacaoLocal(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _localNotif.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _canal.id,
          _canal.name,
          channelDescription: _canal.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['tipo']?.toString(),
    );
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
        debugPrint('[Push] Mensagem recebida (foreground): ${message.data}');
        // SOS em foreground → abre o alarme full-screen directamente.
        if (message.data['tipo']?.toString() == 'sos') {
          _abrirAlarmeSos(message.data);
          return;
        }
        _mostrarNotificacaoLocal(message);
        _mostrarSnackbar(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[Push] App aberta via notificação: ${message.data}');
        _abrirDestino(message);
      });

      // App lançada a partir de uma notificação SOS (estava fechada):
      // verifica tanto o FCM como a notificação local full-screen.
      final msgInicial = await _messaging.getInitialMessage();
      if (msgInicial != null && msgInicial.data['tipo']?.toString() == 'sos') {
        _abrirAposArranque(() => _abrirAlarmeSos(msgInicial.data));
      } else {
        final launch = await _localNotif.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp ?? false) {
          final payload = launch!.notificationResponse?.payload;
          _abrirAposArranque(() => _abrirAlarmeDePayload(payload));
        }
      }
    } catch (e) {
      debugPrint('[Push] Erro setup: $e');
    }
  }

  /// Atrasa a abertura do alarme para depois do arranque (splash → home),
  /// para o Get.to não correr antes do GetMaterialApp estar montado.
  void _abrirAposArranque(void Function() acao) {
    Future.delayed(const Duration(seconds: 2), acao);
  }

  void _abrirDestino(RemoteMessage message) {
    final data = message.data;
    final tipo = data['tipo']?.toString();
    final avisoId = int.tryParse(data['aviso_id']?.toString() ?? '');
    if (tipo == 'aviso_publicado' && avisoId != null) {
      Get.to(() => AvisoDetalheView(avisoId: avisoId));
    } else if (tipo == 'sos') {
      _abrirAlarmeSos(data);
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
