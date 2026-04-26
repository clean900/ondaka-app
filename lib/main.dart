import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase ANTES dos services (push depende dele)
  await Firebase.initializeApp();

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
