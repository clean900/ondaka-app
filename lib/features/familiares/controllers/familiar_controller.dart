import 'package:get/get.dart';
import '../models/familiar.dart';
import '../repositories/familiar_repository.dart';

class FamiliarController extends GetxController {
  final FamiliarRepository _repo = FamiliarRepository();

  final carregando = false.obs;
  final aProcessar = false.obs;
  final familiares = <Familiar>[].obs;
  final acessosDisponiveis = <String>[].obs;
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
      familiares.assignAll(resp.familiares);
      acessosDisponiveis.assignAll(resp.acessosDisponiveis);
    } catch (e) {
      erro.value = 'Não foi possível carregar os familiares.';
    } finally {
      carregando.value = false;
    }
  }

  Future<bool> criar({
    required String nome,
    String? parentesco,
    required String telefone,
    String? email,
    required String password,
    required List<String> acessos,
  }) async {
    aProcessar.value = true;
    try {
      await _repo.criar(
        nome: nome, parentesco: parentesco, telefone: telefone,
        email: email, password: password, acessos: acessos,
      );
      await carregar();
      return true;
    } catch (e) {
      erro.value = 'Não foi possível adicionar o familiar.';
      return false;
    } finally {
      aProcessar.value = false;
    }
  }

  Future<bool> atualizarAcessos(int id, List<String> acessos) async {
    aProcessar.value = true;
    try {
      await _repo.atualizar(id, acessos: acessos);
      await carregar();
      return true;
    } catch (e) {
      erro.value = 'Não foi possível atualizar.';
      return false;
    } finally {
      aProcessar.value = false;
    }
  }

  Future<bool> alternarAtivo(Familiar f) async {
    aProcessar.value = true;
    try {
      await _repo.atualizar(f.id, ativo: !f.ativo);
      await carregar();
      return true;
    } catch (e) {
      erro.value = 'Não foi possível alterar o estado.';
      return false;
    } finally {
      aProcessar.value = false;
    }
  }

  Future<bool> remover(int id) async {
    aProcessar.value = true;
    try {
      await _repo.remover(id);
      await carregar();
      return true;
    } catch (e) {
      erro.value = 'Não foi possível remover.';
      return false;
    } finally {
      aProcessar.value = false;
    }
  }
}
