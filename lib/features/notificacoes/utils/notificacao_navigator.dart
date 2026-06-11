import 'package:get/get.dart';

import '../../assembleias/views/assembleia_detalhe_view.dart';
import '../../avisos/views/aviso_detalhe_view.dart';
import '../../extracto/views/extracto_view.dart';
import '../../tickets/views/ticket_detalhe_view.dart';
import '../models/notificacao.dart';

/// Resolve uma notificação para a navegação interna correspondente.
///
/// O backend devolve um `url` estilo web (ex.: `/avisos/123`). No mobile não
/// há rotas web, por isso mapeamos por [NotificacaoTipo] + o id extraído do url.
abstract class NotificacaoNavigator {
  NotificacaoNavigator._();

  /// Abre o destino interno de uma notificação. No-op silencioso se o tipo
  /// não tiver ecrã associado ou faltar o id necessário.
  static void abrir(Notificacao n) {
    final id = _extrairId(n.url);
    switch (n.tipo) {
      case NotificacaoTipo.avisoNovo:
        if (id != null) Get.to(() => AvisoDetalheView(avisoId: id));
        break;
      case NotificacaoTipo.pedidoAtribuido:
      case NotificacaoTipo.pedidoEstado:
        if (id != null) Get.to(() => TicketDetalheView(ticketId: id));
        break;
      case NotificacaoTipo.assembleiaAgendada:
        if (id != null) Get.to(() => AssembleiaDetalheView(assembleiaId: id));
        break;
      case NotificacaoTipo.quotaEmitida:
      case NotificacaoTipo.pagamentoConfirmado:
      case NotificacaoTipo.pagamentoFalhou:
        Get.to(() => const ExtractoView());
        break;
      case NotificacaoTipo.generica:
        break;
    }
  }

  /// Extrai o último inteiro do caminho do url (ex.: `/avisos/123` -> 123).
  static int? _extrairId(String? url) {
    if (url == null || url.isEmpty) return null;
    final matches = RegExp(r'\d+').allMatches(url);
    if (matches.isEmpty) return null;
    return int.tryParse(matches.last.group(0)!);
  }
}
