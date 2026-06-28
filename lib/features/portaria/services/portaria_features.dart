import '../repositories/portaria_repository.dart';

/// Cache dos add-ons da portaria activos para a empresa (carrega uma vez).
/// Evita que cada ecrã sonde o backend separadamente.
class PortariaFeatures {
  PortariaFeatures._();
  static final PortariaFeatures instance = PortariaFeatures._();

  Map<String, bool> _flags = {};
  bool _carregado = false;

  bool ativo(String slug) => _flags[slug] ?? false;

  /// Garante que os flags estão carregados (só faz o pedido uma vez).
  Future<void> garantirCarregado() async {
    if (_carregado) return;
    try {
      _flags = await PortariaRepository().features();
      _carregado = true;
    } catch (_) {
      // sem add-ons / erro → tudo fica false
    }
  }

  /// Força recarregar (ex.: após o gestor activar um add-on).
  Future<void> recarregar() async {
    _carregado = false;
    await garantirCarregado();
  }
}
