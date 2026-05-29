import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../me/models/me_fraccoes.dart';
import '../../me/repositories/me_repository.dart';
import '../models/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Controller para criar um novo pedido de intervencao.
class CriarTicketController extends GetxController {
  final TicketRepository _repo;
  final MeRepository _meRepo;
  final ImagePicker _picker = ImagePicker();

  CriarTicketController({TicketRepository? repo, MeRepository? meRepo})
      : _repo = repo ?? TicketRepository(),
        _meRepo = meRepo ?? MeRepository();

  // Condominios + fraccoes do user (carregados em onInit)
  final condominios = <MeuCondominio>[].obs;
  final fraccoes = <MinhaFraccao>[].obs;
  final condominioSelecionado = Rxn<MeuCondominio>();
  final fraccaoSelecionada = Rxn<MinhaFraccao>();
  final isCarregandoFraccoes = false.obs;

  // Tipo: particular (default) ou publico
  final tipo = TicketTipo.particular.obs;

  // Categoria dinamica vinda do backend
  final categorias = <TicketCategoriaDinamica>[].obs;
  final categoriaSelecionada = Rxn<TicketCategoriaDinamica>();
  final isCarregandoCategorias = false.obs;

  // Legado (fallback - se backend nao tiver categoria_id)
  final categoria = TicketCategoria.outro.obs;
  final prioridade = TicketPrioridade.media.obs;

  final fotos = <File>[].obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarCategorias();
    carregarFraccoes();
  }

  /// Carrega condominios e fraccoes do user para os dropdowns.
  Future<void> carregarFraccoes() async {
    isCarregandoFraccoes.value = true;
    try {
      final payload = await _meRepo.fraccoes();
      condominios.value = payload.condominios;
      fraccoes.value = payload.fraccoes;
      // Auto-seleccionar se so houver 1 condominio
      if (payload.condominios.length == 1) {
        condominioSelecionado.value = payload.condominios.first;
        // Auto-seleccionar fraccao se so houver 1
        final fraccoesDoCondominio =
            payload.fraccoesDoCondominio(payload.condominios.first.id);
        if (fraccoesDoCondominio.length == 1) {
          fraccaoSelecionada.value = fraccoesDoCondominio.first;
        }
      }
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        e.response?.data?['message'] as String? ?? 'Erro ao carregar fraccoes.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCarregandoFraccoes.value = false;
    }
  }

  /// Fraccoes filtradas pelo condominio selecionado.
  List<MinhaFraccao> get fraccoesDoCondominio {
    final cond = condominioSelecionado.value;
    if (cond == null) return [];
    return fraccoes.where((f) => f.condominioId == cond.id).toList();
  }

  /// Lista de categorias filtradas pelo tipo selecionado.
  List<TicketCategoriaDinamica> get categoriasDoTipo {
    return categorias.where((c) => c.tipo == tipo.value.slug).toList();
  }

  /// Carrega categorias do backend.
  Future<void> carregarCategorias() async {
    isCarregandoCategorias.value = true;
    try {
      final lista = await _repo.categorias();
      categorias.value = lista;
    } on DioException catch (e) {
      Get.snackbar(
        'Erro',
        e.response?.data?['message'] as String? ?? 'Erro ao carregar categorias.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCarregandoCategorias.value = false;
    }
  }

  /// Adiciona uma foto da galeria ou camara.
  Future<void> adicionarFoto({required ImageSource source}) async {
    if (fotos.length >= 5) {
      Get.snackbar('Limite atingido', 'Maximo 5 fotos por pedido.');
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

  /// Submete o pedido. Retorna o id criado em sucesso, null em erro.
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
        tipo: tipo.value,
        categoriaId: categoriaSelecionada.value?.id,
        categoriaSlug: categoriaSelecionada.value?.slug,
        categoria: categoriaSelecionada.value == null ? categoria.value : null,
        prioridade: prioridade.value,
        fotos: fotos.toList(),
      );

      Get.snackbar(
        'Pedido criado',
        'Pedido #${ticket.id} criado com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return ticket.id;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Erro ao criar.';
      Get.snackbar('Erro', msg, snackPosition: SnackPosition.BOTTOM);
      return null;
    } catch (e) {
      Get.snackbar('Erro', 'Erro inesperado.', snackPosition: SnackPosition.BOTTOM);
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }
}
