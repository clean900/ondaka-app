import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../me/models/me_fraccoes.dart';
import '../../me/repositories/me_repository.dart';
import '../models/passe.dart';
import '../repositories/passe_repository.dart';

class PasseController extends GetxController {
  final PasseRepository _repo;
  final MeRepository _meRepo;
  final ImagePicker _picker = ImagePicker();

  PasseController({PasseRepository? repo, MeRepository? meRepo})
      : _repo = repo ?? PasseRepository(),
        _meRepo = meRepo ?? MeRepository();

  final passes = <Passe>[].obs;
  final fraccoes = <MinhaFraccao>[].obs;
  final isLoading = false.obs;
  final aSubmeter = false.obs;
  final erro = Rx<String?>(null);

  // Form
  final fraccaoId = Rx<int?>(null);
  final tipoAcesso = 'prestador'.obs;
  final nomeVisitante = ''.obs;
  final telefone = ''.obs;
  final tipoDocumento = 'bi'.obs;
  final numeroDocumento = ''.obs;
  final validaDesde = Rx<DateTime?>(null);
  final validaAte = Rx<DateTime?>(null);
  final documentoPath = Rx<String?>(null);
  final fotoPath = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    // Carregamentos independentes — uma falha não bloqueia a outra.
    try {
      passes.assignAll(await _repo.listar());
    } catch (_) {}
    try {
      final payload = await _meRepo.fraccoes();
      fraccoes.assignAll(payload.fraccoes);
      if (fraccaoId.value == null && fraccoes.isNotEmpty) {
        fraccaoId.value = fraccoes.first.id;
      }
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> escolherDocumento() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) documentoPath.value = x.path;
  }

  Future<void> tirarFotoDocumento() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x != null) documentoPath.value = x.path;
  }

  Future<void> tirarFotoVisitante() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (x != null) fotoPath.value = x.path;
  }

  Future<void> escolherFotoVisitante() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (x != null) fotoPath.value = x.path;
  }

  String? _validar() {
    if (fraccaoId.value == null) return 'Escolha o imóvel.';
    if (nomeVisitante.value.trim().isEmpty) return 'Indique o nome do visitante.';
    if (validaDesde.value == null || validaAte.value == null) return 'Defina as datas de validade.';
    if (validaAte.value!.isBefore(validaDesde.value!)) return 'A data final tem de ser após a inicial.';
    if (fotoPath.value == null) return 'Tire uma foto do visitante (vai no passe).';
    if (documentoPath.value == null) return 'Anexe o documento de identificação do visitante.';
    return null;
  }

  Future<bool> submeter() async {
    final e = _validar();
    if (e != null) {
      erro.value = e;
      return false;
    }
    erro.value = null;
    aSubmeter.value = true;
    try {
      await _repo.solicitar(
        fraccaoId: fraccaoId.value!,
        tipoAcesso: tipoAcesso.value,
        nomeVisitante: nomeVisitante.value.trim(),
        telefoneVisitante: telefone.value.trim(),
        tipoDocumento: tipoDocumento.value,
        numeroDocumento: numeroDocumento.value.trim(),
        validaDesde: validaDesde.value!,
        validaAte: validaAte.value!,
        documentoPath: documentoPath.value!,
        fotoVisitantePath: fotoPath.value!,
      );
      _limparForm();
      await carregar();
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        erro.value = data['message'].toString();
      } else if (data is Map && data['errors'] is Map) {
        final errs = (data['errors'] as Map).values;
        erro.value = errs.isNotEmpty ? (errs.first as List).first.toString() : 'Dados inválidos.';
      } else {
        erro.value = 'Erro ao solicitar (HTTP ${e.response?.statusCode ?? 'sem ligação'}).';
      }
      return false;
    } catch (e) {
      erro.value = 'Erro inesperado: $e';
      return false;
    } finally {
      aSubmeter.value = false;
    }
  }

  void _limparForm() {
    nomeVisitante.value = '';
    telefone.value = '';
    numeroDocumento.value = '';
    validaDesde.value = null;
    validaAte.value = null;
    documentoPath.value = null;
    fotoPath.value = null;
  }
}
