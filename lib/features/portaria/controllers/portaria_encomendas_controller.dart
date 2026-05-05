import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../encomendas/models/encomenda.dart';
import '../repositories/portaria_encomenda_repository.dart';

/// Controller para gestão de encomendas no perfil PORTARIA (guarda).
class PortariaEncomendasController extends GetxController {
  final _repo = PortariaEncomendaRepository();

  // Listas
  final aguardaChegada = <Encomenda>[].obs;
  final naPortaria = <Encomenda>[].obs;
  final historico = <Encomenda>[].obs;

  // Estados
  final isLoadingAguarda = false.obs;
  final isLoadingPortaria = false.obs;
  final isLoadingHistorico = false.obs;
  final erro = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregarAmbas();
  }

  Future<void> carregarAmbas() async {
    await Future.wait([
      carregarAguardaChegada(),
      carregarNaPortaria(),
      carregarHistorico(),
    ]);
  }

  Future<void> carregarAguardaChegada() async {
    isLoadingAguarda.value = true;
    erro.value = null;
    try {
      aguardaChegada.value = await _repo.aguardaChegada();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar pré-anúncios.';
    } finally {
      isLoadingAguarda.value = false;
    }
  }

  Future<void> carregarNaPortaria() async {
    isLoadingPortaria.value = true;
    erro.value = null;
    try {
      naPortaria.value = await _repo.naPortaria();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar encomendas em portaria.';
    } finally {
      isLoadingPortaria.value = false;
    }
  }

  Future<void> carregarHistorico() async {
    isLoadingHistorico.value = true;
    erro.value = null;
    try {
      historico.value = await _repo.historico();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar histórico.';
    } finally {
      isLoadingHistorico.value = false;
    }
  }

  /// Marca chegada de pré-anúncio (move de Aguardam para Portaria).
  Future<bool> marcarChegada(int id, {String? notas}) async {
    try {
      await _repo.marcarChegada(id, notas: notas);
      Get.snackbar(
        'Sucesso',
        'Encomenda registada na portaria.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await carregarAmbas();
      return true;
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        _extrairErro(e),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Entrega encomenda (titular ou pessoa autorizada).
  Future<bool> entregar(
    int id, {
    String? levantadaPor,
    int? fraccaoAutorizadoId,
  }) async {
    try {
      await _repo.entregar(
        id,
        levantadaPor: levantadaPor,
        fraccaoAutorizadoId: fraccaoAutorizadoId,
      );
      Get.snackbar(
        'Sucesso',
        'Encomenda entregue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await Future.wait([carregarNaPortaria(), carregarHistorico()]);
      return true;
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        _extrairErro(e),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Registar encomenda manual (Fluxo A).
  Future<bool> registarManual({
    required int fraccaoId,
    required String descricao,
    String? remetente,
    String? notas,
  }) async {
    try {
      await _repo.registarManual(
        fraccaoId: fraccaoId,
        descricao: descricao,
        remetente: remetente,
        notas: notas,
      );
      Get.snackbar(
        'Sucesso',
        'Encomenda registada.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await carregarNaPortaria();
      return true;
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        _extrairErro(e),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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
