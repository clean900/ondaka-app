import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/pagamento.dart';
import '../repositories/pagamento_repository.dart';
import 'extracto_controller.dart';

/// Controller para gestão de pagamentos do condómino.
///
/// Notas:
/// - Após criar/editar/cancelar pagamento, recarrega o extracto
///   para reflectir o estado actualizado.
class PagamentoController extends GetxController {
  final _repo = PagamentoRepository();

  // Estado
  final pagamentos = <Pagamento>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final erro = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      pagamentos.value = await _repo.listar();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar pagamentos.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Submete novo pagamento.
  /// Retorna `true` se sucesso, `false` se falhou.
  Future<bool> submeter({
    required int fraccaoId,
    required String metodo,
    required double valor,
    required DateTime dataPagamento,
    List<int>? lancamentoIds,
    String? referenciaExterna,
    String? bancoOrigem,
    String? notasCondomino,
    File? comprovativo,
  }) async {
    isSubmitting.value = true;
    erro.value = null;
    try {
      await _repo.submeter(
        fraccaoId: fraccaoId,
        metodo: metodo,
        valor: valor,
        dataPagamento: dataPagamento,
        lancamentoIds: lancamentoIds,
        referenciaExterna: referenciaExterna,
        bancoOrigem: bancoOrigem,
        notasCondomino: notasCondomino,
        comprovativo: comprovativo,
      );
      await carregar();
      // Recarregar extracto também (saldo + movimentos)
      _recarregarExtractoSeExiste();
      return true;
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
      return false;
    } catch (_) {
      erro.value = 'Erro ao submeter pagamento.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Gera referência ProxyPay para um pagamento existente.
  /// Retorna o Map de referência (reference_id, entity_id, amount, expira_em).
  Future<Map<String, dynamic>?> gerarReferenciaMcx(int pagamentoId) async {
    isSubmitting.value = true;
    erro.value = null;
    try {
      final r = await _repo.gerarReferenciaMcx(pagamentoId);
      return r;
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
      return null;
    } catch (_) {
      erro.value = 'Erro ao gerar referência.';
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelar(int id) async {
    isSubmitting.value = true;
    erro.value = null;
    try {
      await _repo.cancelar(id);
      await carregar();
      _recarregarExtractoSeExiste();
      return true;
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
      return false;
    } catch (_) {
      erro.value = 'Erro ao cancelar pagamento.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _recarregarExtractoSeExiste() {
    if (Get.isRegistered<ExtractoController>()) {
      Get.find<ExtractoController>().carregarTudo();
    }
  }

  String _extrairErro(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (data is Map && data['errors'] is Map) {
      final errors = (data['errors'] as Map).values.toList();
      if (errors.isNotEmpty && errors.first is List) {
        return (errors.first as List).first.toString();
      }
    }
    return 'Erro de ligação. Tenta novamente.';
  }
}
