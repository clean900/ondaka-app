import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Toque de chamada recebida (loop até atender/recusar). Singleton.
/// Usa o toque genérico do próprio sistema (não a sirene do SOS).
class ChamadaRing {
  ChamadaRing._();
  static final ChamadaRing instance = ChamadaRing._();

  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();
  bool aTocar = false;

  Future<void> tocar() async {
    if (aTocar) return;
    aTocar = true;
    try {
      await _player.playRingtone(looping: true);
    } catch (_) {
      aTocar = false;
    }
  }

  Future<void> parar() async {
    aTocar = false;
    try {
      await _player.stop();
    } catch (_) {}
  }
}
