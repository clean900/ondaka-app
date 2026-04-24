import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/models/visita.dart';
import '../repositories/portaria_repository.dart';

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
      final visita = await _repository.validarOtp(otp);
      visitaAutorizada.value = visita;
    } on DioException catch (e) {
      errorMessage.value = _extrairErroDio(e);
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  void proximaValidacao() {
    otpController.clear();
    errorMessage.value = null;
    visitaAutorizada.value = null;
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
