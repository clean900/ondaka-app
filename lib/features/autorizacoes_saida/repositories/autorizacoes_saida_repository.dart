import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../portaria/repositories/portaria_repository.dart' show AddonInativoException;
import '../models/pedido_autorizacao_bem.dart';

/// Autorizações de saída de bens (lado do condómino/gestor).
class AutorizacoesSaidaRepository {
  final Dio _dio;

  AutorizacoesSaidaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Lista os bens à espera de autorização (condómino vê os seus; gestor os da empresa).
  /// Lança [AddonInativoException] se o add-on não estiver activo (402).
  Future<List<PedidoAutorizacaoBem>> pendentes() async {
    try {
      final r = await _dio.get('/visitas/itens/pendentes-autorizacao');
      return (r.data['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(PedidoAutorizacaoBem.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        final msg = e.response?.data is Map
            ? (e.response!.data['message']?.toString() ?? 'Add-on não activo.')
            : 'Add-on não activo.';
        throw AddonInativoException(msg);
      }
      rethrow;
    }
  }

  /// Aprova (true) ou recusa (false) a saída de um bem.
  Future<void> autorizar(int itemId, {required bool aprovar}) async {
    await _dio.post('/visitas/itens/$itemId/autorizar', data: {'aprovar': aprovar});
  }
}
