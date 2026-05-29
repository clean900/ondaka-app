import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/prestador.dart';
import '../repositories/prestadores_repository.dart';

/// Gere o estado do ecrã de prestadores (lista de prestadores).
class PrestadoresController extends GetxController {
  final PrestadoresRepository _repo = PrestadoresRepository();

  final isLoading = false.obs;
  final erro = RxnString();
  final categorias = <PrestadorCategoria>[].obs;
  final prestadores = <Prestador>[].obs;
  final categoriaSeleccionada = RxnInt();
  final addonActivo = true.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    try {
      isLoading.value = true;
      erro.value = null;
      final res = await _repo.listar(categoriaId: categoriaSeleccionada.value);
      addonActivo.value = res.addonActivo;
      categorias.assignAll(res.categorias);
      prestadores.assignAll(res.prestadores);
    } catch (e) {
      erro.value = 'Não foi possível carregar os prestadores.';
    } finally {
      isLoading.value = false;
    }
  }

  void seleccionarCategoria(int? id) {
    categoriaSeleccionada.value =
        categoriaSeleccionada.value == id ? null : id;
    carregar();
  }

  Future<void> refrescar() => carregar();
}

/// Gere o estado do detalhe de um prestador (perfil + avaliações).
class PrestadorDetalheController extends GetxController {
  final PrestadoresRepository _repo = PrestadoresRepository();
  final int prestadorId;

  PrestadorDetalheController(this.prestadorId);

  final isLoading = false.obs;
  final erro = RxnString();
  final prestador = Rxn<Prestador>();
  final avaliacoes = <AvaliacaoPrestador>[].obs;
  final aEnviar = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    try {
      isLoading.value = true;
      erro.value = null;
      final res = await _repo.detalhe(prestadorId);
      prestador.value = res.prestador;
      avaliacoes.assignAll(res.avaliacoes);
    } catch (e) {
      erro.value = 'Não foi possível carregar o prestador.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> enviarAvaliacao(int estrelas, String? comentario) async {
    try {
      aEnviar.value = true;
      await _repo.avaliar(
        prestadorId: prestadorId,
        estrelas: estrelas,
        comentario: comentario,
      );
      await carregar();
      Get.snackbar(
        'Obrigado!',
        'A sua avaliação foi registada.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1D9E75),
        colorText: const Color(0xFFFFFFFF),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a avaliação.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE24B4A),
        colorText: const Color(0xFFFFFFFF),
      );
      return false;
    } finally {
      aEnviar.value = false;
    }
  }
}
