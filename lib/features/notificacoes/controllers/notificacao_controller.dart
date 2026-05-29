import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/notificacao.dart';
import '../repositories/notificacao_repository.dart';

/// Controller global das notificações in-app.
///
/// - Carrega automaticamente no onInit
/// - Polling a cada 60s para actualizar badge do sino
/// - Permite marcar individual ou todas como lidas (optimistic update)
class NotificacaoController extends GetxController {
  final NotificacaoRepository _repo;

  NotificacaoController({NotificacaoRepository? repo})
      : _repo = repo ?? NotificacaoRepository();

  /// Intervalo entre poll automáticos.
  static const Duration pollInterval = Duration(seconds: 60);

  final notificacoes = <Notificacao>[].obs;
  final naoLidas = 0.obs;
  final isLoading = false.obs;
  final erro = RxnString();

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    carregar();
    _iniciarPolling();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  /// Inicia polling periódico que actualiza silenciosamente.
  void _iniciarPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      _carregarSilencioso();
    });
  }

  /// Carrega notificações com indicador de loading visível.
  Future<void> carregar() async {
    isLoading.value = true;
    erro.value = null;
    try {
      final payload = await _repo.listar();
      notificacoes.value = payload.notificacoes;
      naoLidas.value = payload.naoLidas;
    } on DioException catch (e) {
      erro.value = _erroDio(e);
    } catch (e) {
      erro.value = 'Erro inesperado.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega em segundo plano (sem mostrar loading nem erro a piscar).
  Future<void> _carregarSilencioso() async {
    try {
      final payload = await _repo.listar();
      notificacoes.value = payload.notificacoes;
      naoLidas.value = payload.naoLidas;
    } catch (_) {
      // Silencioso — falha de polling não deve incomodar o user
    }
  }

  /// Marca uma notificação como lida.
  /// Usa optimistic update: actualiza UI primeiro, depois sincroniza com backend.
  Future<void> marcarLida(String id) async {
    // Optimistic: actualiza local primeiro
    final idx = notificacoes.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final antes = notificacoes[idx];
    if (antes.lida) return; // Já estava lida, nada a fazer

    notificacoes[idx] = antes.copyWith(lida: true);
    naoLidas.value = (naoLidas.value - 1).clamp(0, 999);

    try {
      await _repo.marcarLida(id);
    } catch (e) {
      // Reverte em caso de erro
      notificacoes[idx] = antes;
      naoLidas.value = naoLidas.value + 1;
      Get.snackbar(
        'Erro',
        'Não foi possível marcar como lida.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Marca todas como lidas — optimistic update também.
  Future<void> marcarTodasLidas() async {
    final antes = List<Notificacao>.from(notificacoes);
    final naoLidasAntes = naoLidas.value;

    notificacoes.value =
        notificacoes.map((n) => n.copyWith(lida: true)).toList();
    naoLidas.value = 0;

    try {
      await _repo.marcarTodasLidas();
    } catch (e) {
      // Reverte
      notificacoes.value = antes;
      naoLidas.value = naoLidasAntes;
      Get.snackbar(
        'Erro',
        'Não foi possível marcar todas como lidas.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Recarrega manualmente (usado em pull-to-refresh).
  Future<void> recarregar() => carregar();

  String _erroDio(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada.';
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Erro ao carregar notificações.';
  }
}
