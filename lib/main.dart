import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/app.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Regista serviços core na ordem correcta das dependências:
  // Storage → API (usa Storage) → Auth (usa API + Storage)
  // GetX chama onInit() automaticamente em cada GetxService.
  await _initServices();

  runApp(const OndakaApp());
}

Future<void> _initServices() async {
  Get.put(StorageService(), permanent: true);
  Get.put(ApiService(), permanent: true);
  Get.put(AuthService(), permanent: true);
}
