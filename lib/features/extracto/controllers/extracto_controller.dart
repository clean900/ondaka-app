import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/extracto_saldo.dart';
import '../models/movimento.dart';
import '../repositories/extracto_repository.dart';

/// Controller do extracto do condómino.
///
/// Carrega saldo + movimentos em paralelo. Mantém estado reactivo
/// para o UI atualizar automaticamente.
class ExtractoController extends GetxController {
  final _repo = ExtractoRepository();

  // Estado
  final saldo = Rxn<ExtractoSaldo>();
  final movimentos = <Movimento>[].obs;

  final isLoadingSaldo = false.obs;
  final isLoadingMovimentos = false.obs;
  final erro = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await Future.wait([
      carregarSaldo(),
      carregarMovimentos(),
    ]);
  }

  Future<void> carregarSaldo() async {
    isLoadingSaldo.value = true;
    erro.value = null;
    try {
      saldo.value = await _repo.obterSaldo();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar saldo.';
    } finally {
      isLoadingSaldo.value = false;
    }
  }

  Future<void> carregarMovimentos() async {
    isLoadingMovimentos.value = true;
    erro.value = null;
    try {
      movimentos.value = await _repo.listarMovimentos(limit: 100);
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar movimentos.';
    } finally {
      isLoadingMovimentos.value = false;
    }
  }

  String _extrairErro(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Erro de ligação. Tenta novamente.';
  }
}
