import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/fraccao.dart';
import '../../../shared/models/visita.dart';
import '../../../shared/models/visitante.dart';
import '../repositories/portaria_repository.dart';
import 'portaria_features.dart';

/// Erro de validação offline (código não encontrado/expirado/já usado).
class OfflineValidacaoException implements Exception {
  final String mensagem;
  OfflineValidacaoException(this.mensagem);
}

/// Modo Offline da Portaria (#6).
///
/// - Mantém em cache (shared_preferences) as pré-aprovações activas + lista negra.
/// - Valida entradas SEM rede contra esse cache e mete-as numa FILA.
/// - Sincroniza a fila para o backend quando há ligação.
///
/// Singleton; `pendentes` é reactivo para a UI mostrar o badge.
class PortariaOfflineService {
  PortariaOfflineService._();
  static final PortariaOfflineService instance = PortariaOfflineService._();

  final PortariaRepository _repo = PortariaRepository();
  final RxInt pendentes = 0.obs;
  final RxString sincronizadoEm = ''.obs;

  /// Nº de tentativas de envio antes de desistir de um item (erro permanente).
  static const _maxTentativas = 5;

  static const _kCache = 'portaria_offline_cache';
  static const _kFila = 'portaria_offline_fila';
  // Pontuais já usados offline — persiste mesmo depois de a fila ser esvaziada,
  // para impedir reuso do mesmo código antes do próximo pull.
  static const _kUsados = 'portaria_offline_usados';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // --- Cache ---

  Future<Map<String, dynamic>> _lerCache() async {
    final raw = (await _prefs).getString(_kCache);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (e) {
      debugPrint('Portaria offline: cache corrompido — $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _lerFila() async {
    final raw = (await _prefs).getString(_kFila);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Portaria offline: fila corrompida — $e');
      return [];
    }
  }

  Future<void> _guardarFila(List<Map<String, dynamic>> fila) async {
    (await _prefs).setString(_kFila, jsonEncode(fila));
    pendentes.value = fila.length;
  }

  Future<Set<int>> _lerUsados() async {
    final raw = (await _prefs).getStringList(_kUsados);
    if (raw == null) return {};
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _guardarUsados(Set<int> usados) async {
    (await _prefs).setStringList(_kUsados, usados.map((e) => e.toString()).toList());
  }

  /// Carrega o contador da fila (chamar no arranque do home do guarda).
  Future<void> carregarEstado() async {
    pendentes.value = (await _lerFila()).length;
    sincronizadoEm.value = (await _lerCache())['sincronizado_em']?.toString() ?? '';
  }

  // --- Pull (descarregar cache) ---

  Future<void> pull() async {
    try {
      final data = await _repo.sincronizarPull();
      (await _prefs).setString(_kCache, jsonEncode(data));
      sincronizadoEm.value = data['sincronizado_em']?.toString() ?? '';
      // Há rede → refresca também os flags de add-ons (podem ter mudado no backend).
      await PortariaFeatures.instance.recarregar();
      // Poda o set de pontuais usados aos que ainda existem no cache (já-usados
      // ficam USADA no backend e saem do pull, logo deixam de ser precisos).
      await _podarUsados(data);
    } catch (e) {
      debugPrint('Portaria offline: pull falhou — $e');
      // sem rede / erro → mantém o cache anterior
    }
  }

  Future<void> _podarUsados(Map<String, dynamic> cache) async {
    final usados = await _lerUsados();
    if (usados.isEmpty) return;
    final pas = (cache['pre_aprovacoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final idsCache = pas.map((p) => (p['id'] as num?)?.toInt()).whereType<int>().toSet();
    final podado = usados.intersection(idsCache);
    if (podado.length != usados.length) {
      await _guardarUsados(podado);
    }
  }

  // --- Flush (enviar fila) ---

  /// Tenta enviar a fila. Devolve quantas sincronizaram, quantas ficaram,
  /// quantas foram descartadas (erro permanente) e se houve erro de rede.
  Future<({int sincronizadas, int restantes, int descartadas, bool erro})> flush() async {
    final fila = await _lerFila();
    if (fila.isEmpty) return (sincronizadas: 0, restantes: 0, descartadas: 0, erro: false);
    try {
      final payload = fila
          .map((e) => {
                'idempotency_key': e['idempotency_key'],
                if (e['qr_token'] != null) 'qr_token': e['qr_token'],
                if (e['otp_code'] != null) 'otp_code': e['otp_code'],
                'entrou_em': e['entrou_em'],
                'metodo': e['metodo'],
              })
          .toList();
      final resultados = await _repo.sincronizarEntradas(payload);
      final okKeys = resultados
          .where((r) => r['ok'] == true)
          .map((r) => r['idempotency_key']?.toString())
          .toSet();

      var sincronizadas = 0;
      var descartadas = 0;
      final restante = <Map<String, dynamic>>[];
      for (final e in fila) {
        final key = e['idempotency_key']?.toString();
        if (okKeys.contains(key)) {
          sincronizadas++;
          continue; // sincronizada (inclui duplicada) → remove da fila
        }
        // Falhou: conta a tentativa; desiste após o limite (erro provavelmente permanente).
        final tentativas = ((e['tentativas'] as num?)?.toInt() ?? 0) + 1;
        if (tentativas >= _maxTentativas) {
          descartadas++;
          debugPrint('Portaria offline: entrada descartada após $tentativas tentativas ($key)');
          continue;
        }
        restante.add({...e, 'tentativas': tentativas});
      }
      await _guardarFila(restante);
      return (sincronizadas: sincronizadas, restantes: restante.length, descartadas: descartadas, erro: false);
    } catch (e) {
      debugPrint('Portaria offline: flush falhou — $e');
      // sem rede → mantém a fila para tentar de novo mais tarde
      return (sincronizadas: 0, restantes: fila.length, descartadas: 0, erro: true);
    }
  }

  /// Conveniência: ao abrir o home com rede, sincroniza fila e refaz o cache.
  Future<({int sincronizadas, int descartadas, bool erro})> sincronizarSeOnline() async {
    final r = await flush();
    await pull();
    await carregarEstado();
    return (sincronizadas: r.sincronizadas, descartadas: r.descartadas, erro: r.erro);
  }

  // --- Validação offline ---

  Future<({Visita visita, Map<String, dynamic>? listaNegra})> validarOffline({String? qr, String? otp}) async {
    final cache = await _lerCache();
    final pas = (cache['pre_aprovacoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    Map<String, dynamic>? pa;
    for (final p in pas) {
      if (qr != null && p['qr_token'] == qr) { pa = p; break; }
      if (otp != null && p['otp_code'] == otp) { pa = p; break; }
    }
    if (pa == null) {
      throw OfflineValidacaoException('Código não encontrado no cache offline. Sincronize quando houver rede.');
    }

    final agora = DateTime.now();
    final ate = DateTime.tryParse(pa['valida_ate']?.toString() ?? '');
    if (ate != null && agora.isAfter(ate)) {
      throw OfflineValidacaoException('Este código expirou.');
    }
    final desde = pa['valida_desde'] != null ? DateTime.tryParse(pa['valida_desde'].toString()) : null;
    if (desde != null && agora.isBefore(desde)) {
      throw OfflineValidacaoException('Este código ainda não é válido.');
    }

    // Pontual já usado offline? (na fila OU no set persistente de usados)
    final paId = (pa['id'] as num?)?.toInt();
    final ehVisita = (pa['tipo_acesso']?.toString() ?? 'visita') == 'visita';
    final fila = await _lerFila();
    final usados = await _lerUsados();
    if (ehVisita && paId != null) {
      final naFila = fila.any((e) => (e['pre_aprovacao_id'] as num?)?.toInt() == paId);
      if (naFila || usados.contains(paId)) {
        throw OfflineValidacaoException('Este código já foi usado (offline).');
      }
    }

    // Enfileirar
    final idem = _uuidV4();
    fila.add({
      'idempotency_key': idem,
      if (qr != null) 'qr_token': qr,
      if (otp != null) 'otp_code': otp,
      'entrou_em': agora.toUtc().toIso8601String(),
      'metodo': qr != null ? 'qr' : 'otp',
      'pre_aprovacao_id': paId,
      'tentativas': 0,
    });
    await _guardarFila(fila);
    // Marca o pontual como usado (persiste mesmo após a fila esvaziar no flush).
    if (ehVisita && paId != null) {
      usados.add(paId);
      await _guardarUsados(usados);
    }

    // Lista negra (por nome) — apenas alerta
    final alerta = _matchListaNegra(cache, pa['nome_visitante']?.toString());

    final fraccaoId = (pa['fraccao_id'] as num?)?.toInt() ?? 0;
    final visita = Visita(
      id: 0,
      empresaGestoraId: 0,
      visitanteId: 0,
      fraccaoId: fraccaoId,
      guardaEntradaId: 0,
      entrouEm: agora,
      metodoValidacao: qr != null ? MetodoValidacao.qr : MetodoValidacao.otp,
      visitante: Visitante(
        id: 0,
        empresaGestoraId: 0,
        nome: pa['nome_visitante']?.toString() ?? 'Visitante',
        telefone: pa['telefone_visitante']?.toString(),
      ),
      fraccao: pa['fraccao'] != null
          ? Fraccao(id: fraccaoId, empresaGestoraId: 0, condominioId: 0, identificador: pa['fraccao'].toString())
          : null,
    );

    return (visita: visita, listaNegra: alerta);
  }

  Map<String, dynamic>? _matchListaNegra(Map<String, dynamic> cache, String? nome) {
    if (nome == null) return null;
    final lista = (cache['lista_negra'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final norm = _normalizar(nome);
    for (final b in lista) {
      if (b['tipo'] == 'nome' && b['valor_normalizado'] == norm) {
        return {'banido': true, 'tipo': 'nome', 'motivo': b['motivo'], 'mensagem': 'Visitante na lista negra (offline).'};
      }
    }
    return null;
  }

  String _normalizar(String v) =>
      v.toUpperCase().replaceAll(RegExp(r'[\s\.\-\/]+'), '');

  String _uuidV4() {
    final r = Random.secure();
    String hex(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final y = (8 + r.nextInt(4)).toRadixString(16); // 8,9,a,b
    return '${hex(8)}-${hex(4)}-4${hex(3)}-$y${hex(3)}-${hex(12)}';
  }
}
