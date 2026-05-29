import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../me/models/me_fraccoes.dart';
import '../../me/repositories/me_repository.dart';
import '../models/tipo_sos.dart';
import '../repositories/sos_repository.dart';

/// Controller do fluxo SOS no mobile.
///
/// Carrega:
///  - Tipos disponíveis (13)
///  - Fracção activa do user (para auto-preencher localização)
///
/// Permite:
///  - Criar alerta
class SosController extends GetxController {
  final _sosRepo = SosRepository();
  final _meRepo = MeRepository();

  // Estado
  final tipos = <TipoSos>[].obs;
  final fraccaoActiva = Rxn<MinhaFraccao>();
  final isLoading = false.obs;
  final isEnviando = false.obs;
  final erro = RxnString();

  // Resultado do último envio
  final ultimoAlerta = Rxn<AlertaCriado>();

  // Fotos opcionais (máx 3)
  final fotos = <File>[].obs;
  final _picker = ImagePicker();
  static const int maxFotos = 3;

  Future<void> adicionarFotoCamera() async {
    if (fotos.length >= maxFotos) return;
    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (xfile != null) fotos.add(File(xfile.path));
  }

  Future<void> adicionarFotoGaleria() async {
    if (fotos.length >= maxFotos) return;
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (xfile != null) fotos.add(File(xfile.path));
  }

  void removerFoto(int index) {
    if (index >= 0 && index < fotos.length) {
      fotos.removeAt(index);
    }
  }

  void limparFotos() {
    fotos.clear();
  }

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      // Carregar tipos + fracções em paralelo
      final resultados = await Future.wait<dynamic>([
        _sosRepo.obterTipos(),
        _meRepo.fraccoes(),
      ]);
      tipos.value = resultados[0] as List<TipoSos>;
      final payload = resultados[1] as MeFraccoesPayload;
      // Primeira fracção como default (geralmente o user só tem uma)
      if (payload.fraccoes.isNotEmpty) {
        fraccaoActiva.value = payload.fraccoes.first;
      }
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
    } catch (_) {
      erro.value = 'Erro ao carregar SOS.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Envia um alerta SOS.
  /// Devolve o alerta criado ou null em caso de erro.
  Future<AlertaCriado?> enviarAlerta({
    required String tipo,
    String? descricao,
    String? localizacao,
  }) async {
    isEnviando.value = true;
    erro.value = null;
    try {
      final alerta = await _sosRepo.criarAlerta(
        tipo: tipo,
        descricao: descricao,
        localizacao: localizacao,
        fotos: fotos.toList(),
      );
      ultimoAlerta.value = alerta;
      limparFotos();
      return alerta;
    } on DioException catch (e) {
      erro.value = _extrairErro(e);
      return null;
    } catch (_) {
      erro.value = 'Erro ao enviar SOS. Tenta novamente.';
      return null;
    } finally {
      isEnviando.value = false;
    }
  }

  /// Tipos filtrados por gravidade.
  List<TipoSos> tiposPorGravidade(GravidadeSos g) {
    return tipos.where((t) => t.gravidade == g).toList();
  }

  /// Localização sugerida para auto-fill.
  String localizacaoSugerida() {
    final f = fraccaoActiva.value;
    if (f == null) return '';
    return f.labelCompleto;
  }

  String _extrairErro(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Erro de ligação. Tenta novamente.';
  }
}
