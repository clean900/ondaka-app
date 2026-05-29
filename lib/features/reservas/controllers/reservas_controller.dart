import 'package:get/get.dart';
import '../models/reserva_models.dart';
import '../repositories/reservas_repository.dart';

class ReservasController extends GetxController {
  final ReservasRepository _repo = ReservasRepository();

  final espacos = <ReservaEspaco>[].obs;
  final addonActivo = true.obs;
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
      final r = await _repo.espacos();
      addonActivo.value = r.addonActivo;
      espacos.value = r.espacos;
    } catch (e) {
      erro.value = 'Não foi possível carregar.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refrescar() => carregar();

  Future<Map<String, dynamic>> criar({
    required int espacoId,
    required String data,
    required String horaInicio,
    required String horaFim,
    String? motivo,
  }) {
    return _repo.criar(
      espacoId: espacoId,
      data: data,
      horaInicio: horaInicio,
      horaFim: horaFim,
      motivo: motivo,
    );
  }

  Future<List<Map<String, String>>> disponibilidade(int espacoId, String data) =>
      _repo.disponibilidade(espacoId, data);
}
