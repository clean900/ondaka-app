import 'package:audioplayers/audioplayers.dart';

/// Toque de chamada recebida (loop até atender/recusar). Singleton.
/// TODO: trocar 'audio/sirene.mp3' por um ringtone próprio (assets/audio/toque_chamada.mp3).
class ChamadaRing {
  ChamadaRing._();
  static final ChamadaRing instance = ChamadaRing._();

  final AudioPlayer _player = AudioPlayer();
  bool aTocar = false;

  Future<void> tocar() async {
    if (aTocar) return;
    aTocar = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/sirene.mp3'), volume: 0.7);
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
