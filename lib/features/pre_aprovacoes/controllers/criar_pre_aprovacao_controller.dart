import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../models/pre_aprovacao.dart';
import '../repositories/pre_aprovacao_repository.dart';

/// Controller para o ecrã "Criar Pré-Aprovação".
///
/// Gere:
/// - Estado do form (campos reactivos)
/// - Validação local
/// - Chamada ao repository
/// - Loading / error states
/// - Navegação pós-sucesso
class CriarPreAprovacaoController extends GetxController {
  final PreAprovacaoRepository _repository;

  CriarPreAprovacaoController({PreAprovacaoRepository? repository})
      : _repository = repository ?? PreAprovacaoRepository();

  // === Form state ===
  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final observacoesController = TextEditingController();

  // Fracção seleccionada (por enquanto fixo — vamos melhorar mais tarde)
  // TODO: buscar fracções do condomino via API quando tivermos endpoint
  final fraccaoId = 68.obs;

  // Data de validade (reactiva)
  final validaAte = Rx<DateTime?>(null);

  // === UI state ===
  final isLoading = false.obs;
  final errorMessage = Rx<String?>(null);
  final preAprovacaoCriada = Rx<PreAprovacao?>(null);

  @override
  void onClose() {
    nomeController.dispose();
    telefoneController.dispose();
    observacoesController.dispose();
    super.onClose();
  }

  // === Actions ===

  /// Define validade através de atalho ("hoje +4h", "amanhã 20h", etc).
  void definirValidadeAtalho(DateTime novaData) {
    validaAte.value = novaData;
  }

  /// Submete o formulário.
  Future<void> submeter() async {
    // Validação local
    if (nomeController.text.trim().length < 2) {
      errorMessage.value = 'Nome do visitante deve ter pelo menos 2 caracteres.';
      return;
    }

    if (telefoneController.text.trim().length < 9) {
      errorMessage.value = 'Telefone inválido.';
      return;
    }

    if (validaAte.value == null) {
      errorMessage.value = 'Escolha até quando é válida a pré-aprovação.';
      return;
    }

    if (validaAte.value!.isBefore(DateTime.now())) {
      errorMessage.value = 'A data de validade deve estar no futuro.';
      return;
    }

    // Limpar estado
    errorMessage.value = null;
    isLoading.value = true;

    try {
      final pa = await _repository.criar(
        fraccaoId: fraccaoId.value,
        nomeVisitante: nomeController.text.trim(),
        telefoneVisitante: _formatarTelefone(telefoneController.text.trim()),
        validaAte: validaAte.value!,
        observacoes: observacoesController.text.trim().isEmpty
            ? null
            : observacoesController.text.trim(),
      );

      preAprovacaoCriada.value = pa;
    } on DioException catch (e) {
      errorMessage.value = _extrairErroDio(e);
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Fecha o ecrã e volta para a home.
  void fecharESair() {
    Get.offAllNamed(AppRoutes.home);
  }

  // === Privados ===

  /// Normaliza o telefone para formato +244XXXXXXXXX esperado pela API.
  String _formatarTelefone(String input) {
    final digitos = input.replaceAll(RegExp(r'[^\d]'), '');

    if (digitos.startsWith('244') && digitos.length == 12) {
      return '+$digitos';
    }

    if (digitos.length == 9) {
      return '+244$digitos';
    }

    // Qualquer outro formato — devolver como está e deixar a API queixar-se
    return input;
  }

  /// Extrai mensagem de erro útil de um DioException.
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

    return 'Erro ao criar pré-aprovação. Tente novamente.';
  }
}
