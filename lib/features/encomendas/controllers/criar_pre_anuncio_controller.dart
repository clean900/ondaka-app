import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/encomenda.dart';
import '../repositories/encomenda_repository.dart';

/// Controller para o formulário de criar pré-anúncio.
class CriarPreAnuncioController extends GetxController {
  final EncomendaRepository _repo;

  CriarPreAnuncioController({EncomendaRepository? repo})
      : _repo = repo ?? EncomendaRepository();

  final descricao = ''.obs;
  final remetente = ''.obs;
  final janelaInicio = Rxn<DateTime>();
  final janelaFim = Rxn<DateTime>();

  final isSubmetendo = false.obs;
  final erro = RxnString();

  bool get podeSubmeter =>
      descricao.value.trim().length >= 2 && !isSubmetendo.value;

  /// Submete o pré-anúncio ao backend.
  /// Retorna a encomenda criada ou null em caso de erro.
  Future<Encomenda?> submeter() async {
    if (!podeSubmeter) return null;
    isSubmetendo.value = true;
    erro.value = null;

    try {
      final criada = await _repo.preAnunciar(
        descricao: descricao.value.trim(),
        remetente: remetente.value.trim().isEmpty ? null : remetente.value.trim(),
        janelaInicio: janelaInicio.value,
        janelaFim: janelaFim.value,
      );
      return criada;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        erro.value = data['message'].toString();
      } else {
        erro.value = 'Erro de ligação.';
      }
      return null;
    } catch (_) {
      erro.value = 'Erro inesperado.';
      return null;
    } finally {
      isSubmetendo.value = false;
    }
  }

  void reset() {
    descricao.value = '';
    remetente.value = '';
    janelaInicio.value = null;
    janelaFim.value = null;
    erro.value = null;
  }
}
