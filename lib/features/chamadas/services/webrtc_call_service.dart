import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../repositories/chamada_repository.dart';
import '../utils/chamada_ring.dart';
import '../views/chamada_em_curso_view.dart';
import '../views/chamada_recebida_view.dart';

/// Estado da chamada de voz WebRTC.
enum EstadoChamada {
  inactiva, // sem chamada
  aLigar, // chamador: à espera que o outro atenda
  aReceber, // recetor: a tocar, antes de atender
  aLigarPeer, // negociação SDP/ICE em curso
  emCurso, // áudio ligado
  terminada,
}

/// Serviço único de chamadas de voz WebRTC (portaria ↔ morador ↔ gestor).
///
/// - Sinalização: WebSocket próprio no VPS (apenas faz relay entre os 2 peers
///   da sala; emite `peer-joined` / `peer-left`).
/// - Media: áudio-only via flutter_webrtc (coturn/STUN/TURN vindos do backend).
///
/// O chamador faz sempre a oferta (offer); o recetor responde (answer). Isto
/// evita "glare" porque os papéis são fixos por chamada.
class WebrtcCallService extends GetxService {
  static WebrtcCallService get to => Get.find();

  final ChamadaRepository _repo = ChamadaRepository();

  // Estado observável para a UI.
  final estado = EstadoChamada.inactiva.obs;
  final nomeOutro = ''.obs; // nome de quem liga / para quem se liga
  final mudo = false.obs;
  final altifalante = false.obs;
  final duracao = 0.obs; // segundos em curso

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  Timer? _timerDuracao;

  bool _souChamador = false;
  bool _ofertaEnviada = false;

  /// Há uma chamada activa (a ligar, a receber ou em curso)?
  bool get activa => estado.value != EstadoChamada.inactiva &&
      estado.value != EstadoChamada.terminada;

  // ---------------------------------------------------------------------------
  // CHAMADOR — inicia uma chamada (POST /chamadas) e abre o ecrã em curso.
  // ---------------------------------------------------------------------------
  Future<void> iniciar({required String destino, int? fraccaoId}) async {
    if (activa) return;
    estado.value = EstadoChamada.aLigar;
    nomeOutro.value = '...';
    try {
      final cfg = await _repo.iniciarChamada(destino: destino, fraccaoId: fraccaoId);
      _souChamador = true;
      nomeOutro.value = cfg.destino;
      Get.to(() => const ChamadaEmCursoView());
      await _arrancar(
        signalingUrl: cfg.signalingUrl,
        iceServers: cfg.iceServers,
      );
    } on Object {
      estado.value = EstadoChamada.inactiva;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // RECETOR — chega um push (modo=webrtc): mostra o ecrã a tocar.
  // ---------------------------------------------------------------------------
  void receber(Map<String, dynamic> data) {
    if (activa) return; // já em chamada → ignora (ocupado)
    final room = data['room']?.toString();
    final signalingUrl = data['signaling_url']?.toString();
    final iceRaw = data['ice_servers']?.toString();
    if (room == null || signalingUrl == null || iceRaw == null) return;

    List<Map<String, dynamic>> ice;
    try {
      ice = (jsonDecode(iceRaw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      ice = const [];
    }

    _souChamador = false;
    nomeOutro.value = data['quem_liga']?.toString() ?? 'Chamada';
    estado.value = EstadoChamada.aReceber;

    ChamadaRing.instance.tocar();
    Get.to(() => ChamadaRecebidaView(
          quemLiga: nomeOutro.value,
          origem: data['origem']?.toString() ?? 'portaria',
          onAtender: () => _atender(signalingUrl, ice),
          onRecusar: desligar,
        ));
  }

  /// Recetor carregou em "Atender" → arranca a negociação.
  Future<void> _atender(String signalingUrl, List<Map<String, dynamic>> ice) async {
    await ChamadaRing.instance.parar();
    Get.off(() => const ChamadaEmCursoView());
    await _arrancar(signalingUrl: signalingUrl, iceServers: ice);
  }

  // ---------------------------------------------------------------------------
  // Núcleo: cria a RTCPeerConnection, captura o micro e liga a sinalização.
  // ---------------------------------------------------------------------------
  Future<void> _arrancar({
    required String signalingUrl,
    required List<Map<String, dynamic>> iceServers,
  }) async {
    estado.value = EstadoChamada.aLigarPeer;
    _ofertaEnviada = false;

    try {
      _pc = await createPeerConnection({
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      });

      // Captura áudio do micro (sem vídeo).
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localStream!.getAudioTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      _pc!.onIceCandidate = (RTCIceCandidate c) {
        if (c.candidate == null) return;
        _enviar({
          'type': 'ice',
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      };

      _pc!.onConnectionState = (RTCPeerConnectionState s) {
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _marcarEmCurso();
        } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          if (estado.value == EstadoChamada.emCurso ||
              estado.value == EstadoChamada.aLigarPeer) {
            desligar();
          }
        }
      };

      // O áudio remoto reproduz automaticamente (não precisa de renderer).
      _pc!.onTrack = (RTCTrackEvent e) {};

      _ligarSinalizacao(signalingUrl);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[webrtc] erro a arrancar: $e');
      desligar();
    }
  }

  void _ligarSinalizacao(String url) {
    _ws = WebSocketChannel.connect(Uri.parse(url));
    _wsSub = _ws!.stream.listen(
      _onMensagem,
      onError: (_) => desligar(),
      onDone: () {
        // ligação de sinalização caiu antes de estabelecer áudio
        if (estado.value == EstadoChamada.aLigarPeer) desligar();
      },
    );

    // O recetor sinaliza prontidão; o chamador também, caso chegue por último.
    _enviar({'type': 'ready'});
  }

  Future<void> _onMensagem(dynamic raw) async {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw.toString()) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final tipo = msg['type']?.toString();

    switch (tipo) {
      case 'peer-joined':
      case 'ready':
        // O outro peer está presente → o chamador faz a oferta (uma só vez).
        if (_souChamador && !_ofertaEnviada) {
          await _enviarOferta();
        }
        break;

      case 'offer':
        if (!_souChamador) {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(msg['sdp']?.toString(), 'offer'),
          );
          final answer = await _pc!.createAnswer({});
          await _pc!.setLocalDescription(answer);
          _enviar({'type': 'answer', 'sdp': answer.sdp});
        }
        break;

      case 'answer':
        if (_souChamador) {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(msg['sdp']?.toString(), 'answer'),
          );
        }
        break;

      case 'ice':
        final cand = msg['candidate'];
        if (cand != null) {
          await _pc!.addCandidate(RTCIceCandidate(
            cand.toString(),
            msg['sdpMid']?.toString(),
            msg['sdpMLineIndex'] is int
                ? msg['sdpMLineIndex'] as int
                : int.tryParse(msg['sdpMLineIndex']?.toString() ?? ''),
          ));
        }
        break;

      case 'hangup':
      case 'peer-left':
        desligar();
        break;
    }
  }

  Future<void> _enviarOferta() async {
    _ofertaEnviada = true;
    final offer = await _pc!.createOffer({});
    await _pc!.setLocalDescription(offer);
    _enviar({'type': 'offer', 'sdp': offer.sdp});
  }

  void _enviar(Map<String, dynamic> msg) {
    try {
      _ws?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  void _marcarEmCurso() {
    if (estado.value == EstadoChamada.emCurso) return;
    estado.value = EstadoChamada.emCurso;
    duracao.value = 0;
    _timerDuracao?.cancel();
    _timerDuracao = Timer.periodic(const Duration(seconds: 1), (_) {
      duracao.value++;
    });
  }

  // ---------------------------------------------------------------------------
  // Controlos
  // ---------------------------------------------------------------------------
  void alternarMute() {
    mudo.value = !mudo.value;
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = !mudo.value;
    }
  }

  Future<void> alternarAltifalante() async {
    altifalante.value = !altifalante.value;
    try {
      await Helper.setSpeakerphoneOn(altifalante.value);
    } catch (_) {}
  }

  /// Termina e limpa tudo (avisa o outro peer se possível).
  Future<void> desligar() async {
    if (estado.value == EstadoChamada.terminada ||
        estado.value == EstadoChamada.inactiva) {
      _limpar();
      return;
    }
    estado.value = EstadoChamada.terminada;
    _enviar({'type': 'hangup'});
    await ChamadaRing.instance.parar();
    _limpar();
    // Fecha o ecrã de chamada (em curso ou a tocar) se ainda estiver aberto.
    final rota = Get.currentRoute;
    if (rota.contains('ChamadaEmCurso') || rota.contains('ChamadaRecebida')) {
      Get.back();
    }
    estado.value = EstadoChamada.inactiva;
  }

  void _limpar() {
    _timerDuracao?.cancel();
    _timerDuracao = null;
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;
    for (final t in _localStream?.getTracks() ?? const []) {
      try {
        t.stop();
      } catch (_) {}
    }
    try {
      _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      _pc?.close();
    } catch (_) {}
    _pc = null;
    _souChamador = false;
    _ofertaEnviada = false;
    mudo.value = false;
    altifalante.value = false;
    duracao.value = 0;
  }

  String get duracaoFmt {
    final s = duracao.value;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}
