import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/contactos_empresa.dart';

/// Repository da empresa gestora — leitura via API.
///
/// Endpoints `/api/empresa-gestora/*`.
class EmpresaGestoraRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/empresa-gestora/contactos
  /// Devolve contactos de suporte da empresa associada ao condómino logado.
  Future<ContactosEmpresa> obterContactos() async {
    final r = await _dio.get('/empresa-gestora/contactos');
    return ContactosEmpresa.fromJson(r.data['data'] as Map<String, dynamic>);
  }
}
