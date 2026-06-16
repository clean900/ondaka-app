import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/documento.dart';
import '../repositories/documentos_repository.dart';

class DocumentosController extends GetxController {
  final DocumentosRepository _repo = DocumentosRepository();

  final documentos = <Documento>[].obs;
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
      documentos.assignAll(await _repo.listar());
    } catch (e) {
      erro.value = 'Não foi possível carregar os documentos.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> abrir(Documento d) async {
    final uri = Uri.parse(d.url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch falhou');
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível abrir o documento.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
