import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/models/visita.dart';
import '../repositories/portaria_repository.dart';
import '../services/portaria_offline_service.dart';

/// Controller do ecrã "Validar OTP".
class ValidarOtpController extends GetxController {
  final PortariaRepository _repository;

  ValidarOtpController({PortariaRepository? repository})
      : _repository = repository ?? PortariaRepository();

  // Form
  final otpController = TextEditingController();

  // UI state
  final isLoading = false.obs;
  final errorMessage = Rx<String?>(null);
  final visitaAutorizada = Rx<Visita?>(null);
  // Alerta da Lista Negra (não bloqueia — avisa o guarda).
  final listaNegraAlerta = Rx<Map<String, dynamic>?>(null);
  // Entrada validada em modo OFFLINE (sem rede) — fica pendente de sync.
  final offline = false.obs;

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }

  Future<void> submeter() async {
    final otp = otpController.text.trim();

    // Validação local
    if (otp.length != 6) {
      errorMessage.value = 'O código deve ter 6 dígitos.';
      return;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      errorMessage.value = 'Código inválido (apenas dígitos).';
      return;
    }

    errorMessage.value = null;
    isLoading.value = true;

    try {
      final r = await _repository.validarOtp(otp);
      visitaAutorizada.value = r.visita;
      listaNegraAlerta.value = r.listaNegra;
    } on DioException catch (e) {
      if (_ehOffline(e)) {
        await _validarOffline(otp: otp);
      } else {
        errorMessage.value = _extrairErroDio(e);
      }
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Valida via token lido do QR do visitante (câmara). Reaproveita o mesmo
  /// fluxo de sucesso (visitaAutorizada) do OTP manual.
  Future<void> validarQrToken(String token) async {
    final t = token.trim();
    if (t.isEmpty) {
      errorMessage.value = 'QR inválido.';
      return;
    }

    errorMessage.value = null;
    isLoading.value = true;

    try {
      final r = await _repository.validarQr(t);
      visitaAutorizada.value = r.visita;
      listaNegraAlerta.value = r.listaNegra;
    } on DioException catch (e) {
      if (_ehOffline(e)) {
        await _validarOffline(qr: t);
      } else {
        errorMessage.value = _extrairErroDio(e);
      }
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Sem rede → valida contra o cache offline e mete na fila de sync.
  Future<void> _validarOffline({String? qr, String? otp}) async {
    try {
      final r = await PortariaOfflineService.instance.validarOffline(qr: qr, otp: otp);
      visitaAutorizada.value = r.visita;
      listaNegraAlerta.value = r.listaNegra;
      offline.value = true;
    } on OfflineValidacaoException catch (oe) {
      errorMessage.value = oe.mensagem;
    } catch (_) {
      errorMessage.value = 'Sem ligação e não foi possível validar offline.';
    }
  }

  /// Só erros de CONECTIVIDADE real disparam o fallback offline. Timeouts de
  /// recepção/envio podem significar que o servidor recebeu e respondeu (ex.: 422
  /// código inválido) — não devem virar "sucesso offline".
  bool _ehOffline(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout;

  void proximaValidacao() {
    otpController.clear();
    errorMessage.value = null;
    visitaAutorizada.value = null;
    listaNegraAlerta.value = null;
    offline.value = false;
  }

  void voltar() {
    Get.back();
  }

  String _extrairErroDio(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('message')) {
        return data['message'] as String;
      }
      if (data.containsKey('errors')) {
        final errors = data['errors'] as Map;
        final primeira = errors.values.first as List;
        return primeira.first as String;
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Ligação lenta. Tente novamente.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Sem ligação à internet.';
    }

    return 'Erro ao validar. Tente novamente.';
  }
}
