import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/acordo.dart';
import '../repositories/acordo_repository.dart';

class AcordoController extends GetxController {
  final AcordoRepository _repo = AcordoRepository();

  final carregando = false.obs;
  final aSubmeter = false.obs;
  final acordos = <Acordo>[].obs;
  final Rxn<LimitacaoInfo> limitacao = Rxn<LimitacaoInfo>();
  final erro = RxnString();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    carregando.value = true;
    erro.value = null;
    try {
      final resp = await _repo.listar();
      acordos.assignAll(resp.acordos);
      limitacao.value = resp.limitacao;
    } catch (e) {
      erro.value = 'Não foi possível carregar os acordos.';
    } finally {
      carregando.value = false;
    }
  }

  String _msgErro(Object e) {
    if (e is DioException && e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response!.data['message'].toString();
    }
    return 'Ocorreu um erro. Tente novamente.';
  }

  Future<bool> propor(int numPrestacoes, {String? observacoes}) async {
    aSubmeter.value = true;
    try {
      await _repo.propor(numPrestacoes, observacoes: observacoes);
      await carregar();
      Get.snackbar('Proposta enviada', 'A sua proposta foi enviada para a gestão.',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('Erro', _msgErro(e), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      aSubmeter.value = false;
    }
  }

  Future<bool> contrapropor(int acordoId, int numPrestacoes, {String? observacoes}) async {
    aSubmeter.value = true;
    try {
      await _repo.contrapropor(acordoId, numPrestacoes, observacoes: observacoes);
      await carregar();
      Get.snackbar('Contraproposta enviada', 'A gestão vai analisar a sua contraproposta.',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('Erro', _msgErro(e), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      aSubmeter.value = false;
    }
  }

  Future<bool> aceitar(int acordoId) async {
    aSubmeter.value = true;
    try {
      await _repo.aceitar(acordoId);
      await carregar();
      Get.snackbar('Acordo aceite', 'O acordo foi confirmado. Veja as suas prestações.',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('Erro', _msgErro(e), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      aSubmeter.value = false;
    }
  }

  Future<bool> recusar(int acordoId, {String? motivo}) async {
    aSubmeter.value = true;
    try {
      await _repo.recusar(acordoId, motivo: motivo);
      await carregar();
      Get.snackbar('Acordo recusado', 'A negociação foi encerrada.',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('Erro', _msgErro(e), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      aSubmeter.value = false;
    }
  }

  // Acordo em curso (ativo ou em negociação), se existir
  Acordo? get acordoEmCurso {
    for (final a in acordos) {
      if (a.estaAtivo || a.emNegociacao) return a;
    }
    return null;
  }
}
