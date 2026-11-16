import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../models/afiliado_models.dart';

/// Programa de Afiliados — leitura do portal do afiliado.
///
/// Só lê. A candidatura, a adesão e os dados bancários fazem-se na web
/// (`ondaka.ao/afiliados` e `/afiliado/dados`): são actos com termos a aceitar
/// e um IBAN a conferir, e a API móvel não os expõe.
class AfiliadosRepository {
  Dio get _dio => ApiService.to.dio;

  /// GET /api/afiliado/resumo — ficha, números, escalões e textos prontos.
  Future<PainelAfiliado> painel() async {
    final r = await _dio.get('/afiliado/resumo');
    return PainelAfiliado.fromJson((r.data as Map).cast<String, dynamic>());
  }

  /// GET /api/afiliado/clientes
  Future<List<ClienteIndicado>> clientes() async {
    final r = await _dio.get('/afiliado/clientes');
    final lista = (r.data['clientes'] as List?) ?? [];
    return lista
        .map((e) => ClienteIndicado.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// GET /api/afiliado/comissoes — paginado de 25 em 25.
  /// [estado] = pendente | aprovada | paga | anulada (null = todos).
  Future<PaginaComissoes> comissoes({int pagina = 1, String? estado}) async {
    final r = await _dio.get('/afiliado/comissoes', queryParameters: {
      'page': pagina,
      'estado': ?estado,
    });
    return PaginaComissoes.fromJson((r.data as Map).cast<String, dynamic>());
  }

  /// GET /api/afiliado/pagamentos
  Future<List<PagamentoAfiliado>> pagamentos() async {
    final r = await _dio.get('/afiliado/pagamentos');
    final lista = (r.data['pagamentos'] as List?) ?? [];
    return lista
        .map((e) => PagamentoAfiliado.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
