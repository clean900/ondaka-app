import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase ANTES dos services (push depende dele).
  // Resiliente: se falhar (ex.: config em falta no bundle iOS), a app continua
  // em vez de ficar presa no splash — o push fica indisponível mas o resto funciona.
  try {
    await Firebase.initializeApp();
    // Handler de SOS em background/app fechada (full-screen alarme + sirene).
    FirebaseMessaging.onBackgroundMessage(sosFirebaseBackgroundHandler);
  } catch (e, st) {
    debugPrint('Falha ao inicializar Firebase: $e\n$st');
  }

  // Inicializar dados de formatacao de datas em pt_PT (intl)
  await initializeDateFormatting('pt_PT', null);

  // Regista serviços core na ordem correcta das dependências:
  // Storage → API (usa Storage) → Auth (usa API + Storage) → Push (usa API)
  await _initServices();

  runApp(const OndakaApp());
}

Future<void> _initServices() async {
  Get.put(StorageService(), permanent: true);
  Get.put(ApiService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(PushNotificationService(), permanent: true);
}
