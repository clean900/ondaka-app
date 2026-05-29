import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../../core/services/api_service.dart';
import '../models/reserva_models.dart';

class ReservasRepositoryResult {
  final List<ReservaEspaco> espacos;
  final bool addonActivo;
  ReservasRepositoryResult({required this.espacos, required this.addonActivo});
}

class ReservasRepository {
  final ApiService _api = Get.find<ApiService>();

  /// GET /reservas/espacos — devolve flag addonActivo se 403.
  Future<ReservasRepositoryResult> espacos() async {
    try {
      final res = await _api.dio.get('/reservas/espacos');
      final data = res.data as Map<String, dynamic>;
      final lista = (data['espacos'] as List? ?? []);
      return ReservasRepositoryResult(
        espacos: lista.map((e) => ReservaEspaco.fromJson(e as Map<String, dynamic>)).toList(),
        addonActivo: true,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return ReservasRepositoryResult(espacos: const [], addonActivo: false);
      }
      rethrow;
    }
  }

  /// GET /reservas/espacos/{id}/disponibilidade?data=YYYY-MM-DD — lista de blocos ocupados.
  Future<List<Map<String, String>>> disponibilidade(int espacoId, String data) async {
    final res = await _api.dio.get('/reservas/espacos/$espacoId/disponibilidade', queryParameters: {'data': data});
    final lista = (res.data['ocupadas'] as List? ?? []);
    return lista
        .map<Map<String, String>>((e) => {
              'hora_inicio': (e['hora_inicio'] as String).substring(0, 5),
              'hora_fim': (e['hora_fim'] as String).substring(0, 5),
            })
        .toList();
  }

  /// POST /reservas — cria pedido.
  Future<Map<String, dynamic>> criar({
    required int espacoId,
    required String data,
    required String horaInicio,
    required String horaFim,
    String? motivo,
  }) async {
    try {
      final res = await _api.dio.post('/reservas', data: {
        'espaco_id': espacoId,
        'data': data,
        'hora_inicio': horaInicio,
        'hora_fim': horaFim,
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      });
      return {'ok': true, 'reserva_id': res.data['reserva_id']};
    } on DioException catch (e) {
      final erro = e.response?.data is Map ? (e.response!.data['erro'] as String? ?? 'Erro ao criar reserva') : 'Erro de rede';
      return {'ok': false, 'erro': erro};
    }
  }

  /// GET /reservas/minhas.
  Future<List<MinhaReserva>> minhas() async {
    final res = await _api.dio.get('/reservas/minhas');
    final lista = (res.data['reservas'] as List? ?? []);
    return lista.map((e) => MinhaReserva.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /reservas/{id}/comprovativo — upload do comprovativo de caução.
  Future<Map<String, dynamic>> enviarComprovativo(int reservaId, File ficheiro) async {
    try {
      final formData = FormData.fromMap({
        'ficheiro': await MultipartFile.fromFile(
          ficheiro.path,
          filename: ficheiro.path.split('/').last,
        ),
      });
      final res = await _api.dio.post(
        '/reservas/$reservaId/comprovativo',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return {'ok': res.data['ok'] == true};
    } on DioException catch (e) {
      final erro = e.response?.data is Map ? (e.response!.data['erro'] as String? ?? 'Falha no upload') : 'Erro de rede';
      return {'ok': false, 'erro': erro};
    }
  }
}
