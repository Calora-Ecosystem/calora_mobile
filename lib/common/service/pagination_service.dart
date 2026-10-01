import 'dart:developer';

import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class PaginationService<T> {
  final PagingController<int, T> pagingController;
  final Future<PaginatedResponse<T>> Function(PaginationQuery query) fetchData;
  final int pageSize;

  PaginationQuery _currentQuery;

  /// Bumped on every [refresh]. A response that lands after a refresh
  /// belongs to the old query (e.g. the previous tab) and is dropped, so
  /// it can't leak into — or cut short — the newly selected list.
  int _generation = 0;

  /// Generation of the request still waiting for a response, if any.
  int? _inFlight;

  PaginationService({
    required this.fetchData,
    this.pageSize = 20,
    PaginationQuery? initialQuery,
    PagingController<int, T>? controller,
  }) : _currentQuery = initialQuery ?? const PaginationQuery(),
       pagingController = controller ?? PagingController<int, T>(firstPageKey: 0) {
    pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    final generation = _generation;
    // One request per generation at a time — a second ask for the same
    // query (e.g. the list remounting mid-load) would append the page twice.
    if (_inFlight == generation) return;
    _inFlight = generation;

    log('PaginationService → fetch page: $pageKey', name: 'PaginationService');

    try {
      final query = _buildQuery(pageKey);
      final response = await fetchData(query);
      if (generation != _generation) return;

      if (response.error != null) {
        pagingController.error = Exception(response.error);
        return;
      }

      final items = response.content ?? [];
      final total = response.total ?? 0;

      final isLastPage = pageKey + items.length >= total;
      log('PaginationService: isLastPage calculation: $pageKey + ${items.length} >= $total => $isLastPage', name: 'PaginationService');

      if (isLastPage) {
        pagingController.appendLastPage(items);
      } else {
        pagingController.appendPage(items, pageKey + items.length);
      }
    } catch (e, s) {
      if (generation != _generation) return;
      pagingController.error = e;
      log(
        'PaginationService error: $e',
        name: 'PaginationService',
        error: e,
        stackTrace: s,
      );
    } finally {
      if (_inFlight == generation) _inFlight = null;
    }
  }

  PaginationQuery _buildQuery(int skip) {
    return PaginationQuery(
      skip: skip,
      take: pageSize,
      filteringExpression: _currentQuery.filteringExpression,
      sortPropName: _currentQuery.sortPropName,
      sortDirection: _currentQuery.sortDirection,
    );
  }

  void refresh() {
    log('PaginationService → refresh()', name: 'PaginationService');
    _generation++;
    final orphaned = _inFlight != null;
    final before = pagingController.value;
    pagingController.refresh();
    // Refreshing while the first page is still loading leaves the state
    // unchanged, so the controller notifies nobody and the paged list never
    // asks again — while the response it is waiting for was just dropped.
    // Ask for the first page ourselves, or the list stays a skeleton forever.
    if (orphaned && identical(before, pagingController.value)) {
      pagingController.notifyPageRequestListeners(pagingController.firstPageKey);
    }
  }

  void updateQuery(PaginationQuery query) {
    _currentQuery = query;
    refresh();
  }

  void updateFilter(List<String>? filteringExpression) {
    _currentQuery = PaginationQuery(
      filteringExpression: filteringExpression,
      sortPropName: _currentQuery.sortPropName,
      sortDirection: _currentQuery.sortDirection,
    );
    refresh();
  }

  void updateSort({String? sortPropName, String? sortDirection}) {
    _currentQuery = PaginationQuery(
      filteringExpression: _currentQuery.filteringExpression,
      sortPropName: sortPropName,
      sortDirection: sortDirection,
    );
    refresh();
  }

  void clearFilters() {
    _currentQuery = const PaginationQuery();
    refresh();
  }

  PaginationQuery get currentQuery => _currentQuery;

  bool get hasFilters => _currentQuery.filteringExpression?.isNotEmpty == true || _currentQuery.sortPropName != null;

  void retryLastFailedRequest() => pagingController.retryLastFailedRequest();

  void dispose() => pagingController.dispose();
}
