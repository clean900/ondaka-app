import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../models/familiar.dart';

class FamiliaresResposta {
  final List<Familiar> familiares;
  final List<String> acessosDisponiveis;
  FamiliaresResposta({required this.familiares, required this.acessosDisponiveis});
}

class FamiliarRepository {
  final Dio _dio;
  FamiliarRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  Future<FamiliaresResposta> listar() async {
    final response = await _dio.get('/familiares');
    final body = response.data as Map<String, dynamic>;
    final lista = (body['data'] as List).map((e) => Familiar.fromJson(e as Map<String, dynamic>)).toList();
    final disp = (body['acessos_disponiveis'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return FamiliaresResposta(familiares: lista, acessosDisponiveis: disp);
  }

  Future<void> criar({
    required String nome,
    String? parentesco,
    required String telefone,
    String? email,
    required String password,
    required List<String> acessos,
  }) async {
    await _dio.post('/familiares', data: {
      'nome': nome,
      'parentesco': parentesco,
      'telefone': telefone,
      'email': email,
      'password': password,
      'acessos': acessos,
    });
  }

  Future<void> atualizar(int id, {String? nome, String? parentesco, List<String>? acessos, bool? ativo}) async {
    final data = <String, dynamic>{};
    if (nome != null) data['nome'] = nome;
    if (parentesco != null) data['parentesco'] = parentesco;
    if (acessos != null) data['acessos'] = acessos;
    if (ativo != null) data['ativo'] = ativo;
    await _dio.put('/familiares/$id', data: data);
  }

  Future<void> remover(int id) async {
    await _dio.delete('/familiares/$id');
  }
}
