import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/anuncio.dart';
import '../repositories/marketplace_repository.dart';

/// Estado da lista de anúncios do marketplace.
class MarketplaceController extends GetxController {
  final MarketplaceRepository _repo = MarketplaceRepository();

  final isLoading = false.obs;
  final erro = RxnString();
  final categorias = <MarketplaceCategoria>[].obs;
  final anuncios = <Anuncio>[].obs;
  final categoriaSeleccionada = RxnInt();
  final tipoSeleccionado = RxnString(); // produto | servico | null
  final podePublicar = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    try {
      isLoading.value = true;
      erro.value = null;
      final res = await _repo.listar(
        categoriaId: categoriaSeleccionada.value,
        tipo: tipoSeleccionado.value,
      );
      podePublicar.value = res.podePublicar;
      categorias.assignAll(res.categorias);
      anuncios.assignAll(res.anuncios);
    } catch (e) {
      erro.value = 'Não foi possível carregar os anúncios.';
    } finally {
      isLoading.value = false;
    }
  }

  void seleccionarCategoria(int? id) {
    categoriaSeleccionada.value = categoriaSeleccionada.value == id ? null : id;
    carregar();
  }

  void seleccionarTipo(String? tipo) {
    tipoSeleccionado.value = tipoSeleccionado.value == tipo ? null : tipo;
    carregar();
  }

  Future<void> refrescar() => carregar();
}

/// Estado de "os meus anúncios".
class MeusAnunciosController extends GetxController {
  final MarketplaceRepository _repo = MarketplaceRepository();

  final isLoading = false.obs;
  final anuncios = <Anuncio>[].obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    try {
      isLoading.value = true;
      anuncios.assignAll(await _repo.meus());
    } catch (e) {
      // silencioso
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> alterarEstado(Anuncio a, String novoEstado) async {
    try {
      await _repo.alterarEstado(a.id, novoEstado);
      await carregar();
      Get.snackbar('Actualizado', 'Estado do anúncio actualizado.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1D9E75), colorText: const Color(0xFFFFFFFF));
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível actualizar.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE24B4A), colorText: const Color(0xFFFFFFFF));
    }
  }
}

/// Estado do formulário de criar anúncio.
class CriarAnuncioController extends GetxController {
  final MarketplaceRepository _repo = MarketplaceRepository();
  final aEnviar = false.obs;

  Future<Anuncio?> criar(Map<String, dynamic> dados) async {
    try {
      aEnviar.value = true;
      final res = await _repo.criar(dados);
      if (res.sucesso) {
        Get.snackbar('Publicado!', 'O seu anúncio está visível.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF1D9E75), colorText: const Color(0xFFFFFFFF));
        return res.anuncio;
      } else {
        Get.snackbar(
          res.subscricaoNecessaria ? 'Subscrição necessária' : 'Erro',
          res.erro ?? 'Não foi possível publicar.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE24B4A), colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 4),
        );
        return null;
      }
    } finally {
      aEnviar.value = false;
    }
  }
}
