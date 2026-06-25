import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';

/// Quem o utilizador pode ligar + imóveis (quando aplicável).
typedef Destinos = ({String papel, List<String> destinos, List<({int id, String identificador})> fraccoes});

/// Configuração devolvida ao chamador para arrancar a chamada WebRTC.
typedef ConfigChamada = ({
  String room,
  String signalingUrl,
  List<Map<String, dynamic>> iceServers,
  String destino,
});

class ChamadaRepository {
  final Dio _dio;
  ChamadaRepository({Dio? dio}) : _dio = dio ?? ApiService.to.dio;

  /// Quem este utilizador pode ligar (matriz por papel) + imóveis quando precisa.
  Future<Destinos> destinos() async {
    final r = await _dio.get('/chamadas/destinos');
    final d = r.data as Map<String, dynamic>;
    final fraccoes = ((d['fraccoes'] as List?) ?? [])
        .map((e) => (
              id: e['id'] as int,
              identificador: (e['identificador'] ?? '').toString(),
            ))
        .toList();
    return (
      papel: (d['papel'] ?? '').toString(),
      destinos: ((d['destinos'] as List?) ?? []).map((e) => e.toString()).toList(),
      fraccoes: fraccoes,
    );
  }

  /// Inicia a chamada WebRTC. `destino` ∈ {portaria, morador, gestor}.
  /// `fraccaoId` é obrigatório quando o destino é um morador específico.
  Future<ConfigChamada> iniciarChamada({required String destino, int? fraccaoId}) async {
    final r = await _dio.post('/chamadas', data: {
      'destino': destino,
      if (fraccaoId != null) 'fraccao_id': fraccaoId,
    });
    final d = r.data as Map<String, dynamic>;
    final ice = ((d['ice_servers'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return (
      room: (d['room'] ?? '').toString(),
      signalingUrl: (d['signaling_url'] ?? '').toString(),
      iceServers: ice,
      destino: (d['destino'] ?? 'Chamada').toString(),
    );
  }

  // --- Imóveis do condomínio activo do guarda (mantido para retrocompat). ---
  Future<List<({int id, String identificador})>> fraccoes() async {
    final r = await _dio.get('/portaria/fraccoes');
    final lista = (r.data['data'] as List?) ?? [];
    return lista
        .map((e) => (
              id: e['id'] as int,
              identificador: (e['identificador'] ?? '').toString(),
            ))
        .toList();
  }
}
