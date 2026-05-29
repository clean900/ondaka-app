import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../empresa_gestora/models/contactos_empresa.dart';
import '../../empresa_gestora/repositories/empresa_gestora_repository.dart';

/// Controller da tab Suporte.
///
/// Carrega os contactos da empresa gestora do condómino logado.
class SuporteController extends GetxController {
  final _repo = EmpresaGestoraRepository();

  final contactos = Rxn<ContactosEmpresa>();
  final isLoading = false.obs;
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
      contactos.value = await _repo.obterContactos();
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar contactos.';
    } finally {
      isLoading.value = false;
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
