import 'visita.dart';

/// Resultado paginado da listagem de visitas.
///
/// Espelha a estrutura `{ data: [...], meta: { current_page, last_page, total, per_page } }`
/// devolvida pela API.
class HistoricoVisitasPage {
  final List<Visita> visitas;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  HistoricoVisitasPage({
    required this.visitas,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get temMaisPaginas => currentPage < lastPage;
  bool get vazio => visitas.isEmpty && total == 0;
}
