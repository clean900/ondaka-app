import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/documento.dart';

/// GET /me/documentos — modelos que o gestor tornou visíveis no mobile.
class DocumentosRepository {
  final ApiService _api = Get.find<ApiService>();

  Future<List<Documento>> listar() async {
    final res = await _api.dio.get('/me/documentos');
    final data = res.data as Map<String, dynamic>;
    return (data['documentos'] as List? ?? [])
        .map((e) => Documento.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
