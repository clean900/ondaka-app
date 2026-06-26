import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

/// Mostra a chamada recebida com a UI NATIVA do sistema (CallKit no iOS,
/// ecrã de chamada cheio no Android) — toca mesmo com a app fechada/em
/// segundo plano. Usado tanto pelo handler de background do FCM como pelo
/// WebrtcCallService em foreground.
///
/// O `data` é o payload do push (room, signaling_url, ice_servers, quem_liga,
/// origem). Vai inteiro em `extra` para ser recuperado quando o utilizador
/// atende (mesmo em arranque a frio).
Future<void> mostrarChamadaCallkit(Map<String, dynamic> data) async {
  final room = data['room']?.toString();
  if (room == null || room.isEmpty) return;
  final quemLiga = data['quem_liga']?.toString() ?? 'Chamada';
  final origem = data['origem']?.toString() ?? 'portaria';

  final params = CallKitParams(
    id: room,
    nameCaller: quemLiga,
    appName: 'ONDAKA',
    handle: _legendaOrigem(origem),
    type: 0, // 0 = chamada de voz
    textAccept: 'Atender',
    textDecline: 'Recusar',
    duration: 45000, // toca até 45s
    extra: data,
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      isShowCallID: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0A0A1A',
      actionColor: '#4CAF50',
      textColor: '#FFFFFF',
      incomingCallNotificationChannelName: 'Chamadas',
      isShowFullLockedScreen: true,
      isImportant: true,
    ),
    ios: const IOSParams(
      handleType: 'generic',
      supportsVideo: false,
      audioSessionMode: 'voiceChat',
      ringtonePath: 'system_ringtone_default',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

/// Termina/dispensa qualquer chamada nativa em curso.
Future<void> terminarChamadaCallkit() async {
  try {
    await FlutterCallkitIncoming.endAllCalls();
  } catch (_) {}
}

String _legendaOrigem(String origem) {
  switch (origem) {
    case 'condomino':
      return 'Morador';
    case 'gestor':
      return 'Gestor';
    default:
      return 'Portaria';
  }
}
