import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/catalogo_feature.dart';
import '../repositories/catalogo_repository.dart';

/// Controller da feature Conheça (catálogo de funcionalidades).
class CatalogoController extends GetxController {
  final _repo = CatalogoRepository();

  final categorias = <CatalogoCategoria>[].obs;
  final isLoading = false.obs;
  final erro = RxnString();

  /// Filtros
  final filtroEstado = 'todos'.obs; // 'todos' | 'pronto' | 'curso' | 'breve' | 'roadmap'
  final busca = ''.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      categorias.value = await _repo.obterCatalogo();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar catálogo.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Categorias filtradas (estado + busca). Categorias vazias ficam de fora.
  List<CatalogoCategoria> get filtradas {
    return categorias.map((cat) {
      final filtered = cat.features.where((f) {
        final matchEstado = filtroEstado.value == 'todos' || f.estado == filtroEstado.value;
        final q = busca.value.toLowerCase();
        final matchBusca = q.isEmpty ||
            f.nome.toLowerCase().contains(q) ||
            f.desc.toLowerCase().contains(q);
        return matchEstado && matchBusca;
      }).toList();
      return CatalogoCategoria(
        id: cat.id,
        titulo: cat.titulo,
        iconName: cat.iconName,
        cor: cat.cor,
        descricao: cat.descricao,
        features: filtered,
      );
    }).where((cat) => cat.features.isNotEmpty).toList();
  }

  /// Stats agregadas (de todas as categorias, ignorando filtros)
  Map<String, int> get stats {
    final all = categorias.expand((c) => c.features).toList();
    return {
      'total': all.length,
      'pronto': all.where((f) => f.estado == 'pronto').length,
      'curso': all.where((f) => f.estado == 'curso').length,
      'breve': all.where((f) => f.estado == 'breve').length,
      'roadmap': all.where((f) => f.estado == 'roadmap').length,
    };
  }

  String _extrairErro(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Erro de ligação. Tenta novamente.';
  }
}
