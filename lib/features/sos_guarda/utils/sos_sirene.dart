import 'package:audioplayers/audioplayers.dart';

/// Sirene do guarda — toca em loop quando chega um novo SOS aberto,
/// até o guarda silenciar ou resolver. Singleton.
class SosSirene {
  SosSirene._();
  static final SosSirene instance = SosSirene._();

  final AudioPlayer _player = AudioPlayer();
  bool aTocar = false;

  Future<void> tocar() async {
    if (aTocar) return;
    aTocar = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/sirene.mp3'), volume: 1.0);
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
