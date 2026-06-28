import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'storage_service.dart';
import '../../features/autorizacoes_saida/views/autorizacoes_saida_view.dart';
import '../../features/avisos/views/aviso_detalhe_view.dart';
import '../../features/sos_guarda/views/sos_alarme_view.dart';
import '../../features/sos_guarda/utils/sos_sirene.dart';
import '../../features/chamadas/services/webrtc_call_service.dart';
import '../../features/chamadas/utils/chamada_callkit.dart';

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

/// Canal de chamadas de voz (portaria↔condómino). Full-screen + som default.
const AndroidNotificationChannel canalChamada = AndroidNotificationChannel(
  'ondaka_chamada',
  'Chamadas',
  description: 'Chamadas de voz entre portaria e moradores',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// Handler de mensagens FCM em BACKGROUND/app fechada (isolate separado).
/// Para SOS (data-only), constrói uma notificação full-screen que acorda o
/// ecrã e lança o alarme vermelho mesmo com a app fechada. Tem de ser uma
/// função top-level com @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> sosFirebaseBackgroundHandler(RemoteMessage message) async {
  final tipo = message.data['tipo']?.toString();
  if (tipo != 'sos' && tipo != 'chamada_recebida') return;
  await Firebase.initializeApp();

  // Chamada de voz → UI nativa de chamada (CallKit/ConnectionService): toca como
  // uma chamada a sério, mesmo com a app fechada. Atender arranca o WebRTC.
  if (tipo == 'chamada_recebida') {
    await mostrarChamadaCallkit(Map<String, dynamic>.from(message.data));
    return;
  }

  final fln = FlutterLocalNotificationsPlugin();
  await fln.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  final android = fln
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(canalSos);
  await android?.createNotificationChannel(canalChamada);

  final ehChamada = tipo == 'chamada_recebida';
  final titulo = message.data['titulo']?.toString() ??
      (ehChamada ? '📞 Chamada' : '🚨 SOS');
  final corpo = message.data['corpo']?.toString() ??
      (ehChamada ? 'Chamada recebida' : 'Emergência recebida');

  await fln.show(
    ehChamada ? 20260624 : 20260618,
    titulo,
    corpo,
    NotificationDetails(
      android: AndroidNotificationDetails(
        ehChamada ? canalChamada.id : canalSos.id,
        ehChamada ? canalChamada.name : canalSos.name,
        channelDescription:
            ehChamada ? canalChamada.description : canalSos.description,
        importance: Importance.max,
        priority: Priority.max,
        category: ehChamada
            ? AndroidNotificationCategory.call
            : AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        sound: ehChamada
            ? null
            : const RawResourceAndroidNotificationSound('sirene_sos'),
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
    await androidPlugin?.createNotificationChannel(canalChamada);
    _localNotifPronto = true;
  }

  /// Chamada de voz recebida (modo=webrtc): delega no serviço WebRTC, que
  /// mostra o ecrã full-screen a tocar e trata da negociação ao atender.
  void _abrirChamada(Map<String, dynamic> data) {
    WebrtcCallService.to.receber(Map<String, dynamic>.from(data));
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
      final tipo = data is Map ? data['tipo']?.toString() : null;
      if (tipo == 'sos') {
        _abrirAlarmeSos(Map<String, dynamic>.from(data as Map));
      } else if (tipo == 'chamada_recebida') {
        _abrirChamada(Map<String, dynamic>.from(data as Map));
      } else if (tipo == 'autorizar_saida_bem' || tipo == 'item_nao_declarado') {
        _abrirAutorizacoesSaida();
      }
    } catch (_) {
      // payload antigo (string simples) — ignora.
    }
  }

  /// Abre o ecrã de autorização de saída de bens (add-on Controlo de Bens).
  void _abrirAutorizacoesSaida() {
    Get.to(() => const AutorizacoesSaidaView());
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
        // SOS/Chamada em foreground → abre o ecrã full-screen directamente.
        final tipoFg = message.data['tipo']?.toString();
        if (tipoFg == 'sos') {
          _abrirAlarmeSos(message.data);
          return;
        }
        if (tipoFg == 'chamada_recebida') {
          _abrirChamada(message.data);
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
      final tipoInicial = msgInicial?.data['tipo']?.toString();
      if (msgInicial != null && tipoInicial == 'sos') {
        _abrirAposArranque(() => _abrirAlarmeSos(msgInicial.data));
      } else if (msgInicial != null && tipoInicial == 'chamada_recebida') {
        _abrirAposArranque(() => _abrirChamada(msgInicial.data));
      } else if (msgInicial != null &&
          (tipoInicial == 'autorizar_saida_bem' || tipoInicial == 'item_nao_declarado')) {
        _abrirAposArranque(_abrirAutorizacoesSaida);
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
    } else if (tipo == 'chamada_recebida') {
      _abrirChamada(data);
    } else if (tipo == 'autorizar_saida_bem' || tipo == 'item_nao_declarado') {
      _abrirAutorizacoesSaida();
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
    registarVoipTokenSeIos();
  }

  /// iOS: regista o token VoIP (PushKit) no backend, para receber chamadas
  /// com a app fechada via push VoIP/APNs. O token chega de forma assíncrona
  /// (PushKit), por isso tentamos algumas vezes até estar disponível.
  Future<void> registarVoipTokenSeIos() async {
    if (!Platform.isIOS) return;
    for (var i = 0; i < 6; i++) {
      try {
        final token = (await FlutterCallkitIncoming.getDevicePushTokenVoIP())?.toString() ?? '';
        if (token.isNotEmpty) {
          await ApiService.to.dio.post(
            '/devices/register-fcm-token',
            data: {'token': token, 'platform': 'ios-voip'},
          );
          debugPrint('[Push] Token VoIP registado no backend.');
          return;
        }
      } on DioException catch (e) {
        debugPrint('[Push] Erro a registar token VoIP: ${e.message}');
        return;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
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
