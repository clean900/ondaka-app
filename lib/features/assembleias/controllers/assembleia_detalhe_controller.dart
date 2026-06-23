import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

import '../models/assembleia.dart';
import '../repositories/assembleia_repository.dart';

class AssembleiaDetalheController extends GetxController {
  final AssembleiaRepository _repo;
  final int assembleiaId;

  AssembleiaDetalheController({
    required this.assembleiaId,
    AssembleiaRepository? repo,
  }) : _repo = repo ?? AssembleiaRepository();

  final detalhe = Rxn<AssembleiaDetalhe>();
  final isLoading = false.obs;
  final isVotando = false.obs;
  final isAbrindoActa = false.obs;
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
      detalhe.value = await _repo.obter(assembleiaId);
    } on DioException catch (e) {
      erro.value = e.response?.data?['message'] as String? ?? 'Erro.';
    } catch (_) {
      // Qualquer outro erro (ex.: parse) mostra estado de erro, nao ecra preto.
      erro.value = 'Nao foi possivel carregar a assembleia.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> votar({required int pontoId, required String opcao}) async {
    if (isVotando.value) return false;
    isVotando.value = true;
    try {
      await _repo.votar(
        assembleiaId: assembleiaId,
        pontoId: pontoId,
        opcao: opcao,
      );
      Get.snackbar('Voto registado', 'O teu voto foi guardado.',
          snackPosition: SnackPosition.BOTTOM);
      await carregar();
      return true;
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        e.response?.data?['message'] as String? ?? 'Erro ao votar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isVotando.value = false;
    }
  }

  /// Marca presença ao entrar na sala virtual. Falha silenciosamente — não
  /// deve impedir o utilizador de abrir o Jitsi.
  Future<void> registarPresenca() async {
    try {
      await _repo.entrar(assembleiaId);
    } catch (_) {
      // Presença é best-effort; não bloquear a entrada na sala.
    }
  }

  /// Descarrega a acta (PDF) e abre-a no visualizador do sistema.
  Future<void> abrirActa() async {
    if (isAbrindoActa.value) return;
    isAbrindoActa.value = true;
    try {
      final caminho = await _repo.descarregarActa(assembleiaId);
      await OpenFile.open(caminho);
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        e.response?.data?['message'] as String? ??
            'Não foi possível abrir a acta.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível abrir a acta.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isAbrindoActa.value = false;
    }
  }
}
