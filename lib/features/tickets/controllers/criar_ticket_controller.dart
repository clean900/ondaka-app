import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Controller para criar um novo ticket.
class CriarTicketController extends GetxController {
  final TicketRepository _repo;
  final ImagePicker _picker = ImagePicker();

  CriarTicketController({TicketRepository? repo})
      : _repo = repo ?? TicketRepository();

  final categoria = TicketCategoria.outro.obs;
  final prioridade = TicketPrioridade.media.obs;
  final fotos = <File>[].obs;
  final isSubmitting = false.obs;

  /// Adiciona uma foto da galeria ou câmara.
  Future<void> adicionarFoto({required ImageSource source}) async {
    if (fotos.length >= 5) {
      Get.snackbar('Limite atingido', 'Máximo 5 fotos por ticket.');
      return;
    }

    final XFile? imagem = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (imagem != null) {
      fotos.add(File(imagem.path));
    }
  }

  void removerFoto(int index) {
    if (index >= 0 && index < fotos.length) {
      fotos.removeAt(index);
    }
  }

  /// Submete o ticket. Retorna o id criado em sucesso, null em erro.
  Future<int?> submeter({
    required int condominioId,
    int? fraccaoId,
    required String titulo,
    required String descricao,
  }) async {
    if (isSubmitting.value) return null;
    isSubmitting.value = true;

    try {
      final ticket = await _repo.criar(
        condominioId: condominioId,
        fraccaoId: fraccaoId,
        titulo: titulo,
        descricao: descricao,
        categoria: categoria.value,
        prioridade: prioridade.value,
        fotos: fotos.toList(),
      );

      Get.snackbar(
        'Ticket criado',
        'Ticket #${ticket.id} criado com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return ticket.id;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Erro ao criar.';
      Get.snackbar('Erro', msg, snackPosition: SnackPosition.BOTTOM);
      return null;
    } catch (e) {
      Get.snackbar('Erro', 'Erro inesperado.',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }
}
