import 'dart:developer';

import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class PaginationService<T> {
  final PagingController<int, T> pagingController;
  final Future<PaginatedResponse<T>> Function(PaginationQuery query) fetchData;
  final int pageSize;

  PaginationQuery _currentQuery;

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
    log('PaginationService → fetch page: $pageKey', name: 'PaginationService');

    try {
      final query = _buildQuery(pageKey);
      final response = await fetchData(query);

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
      pagingController.error = e;
      log(
        'PaginationService error: $e',
        name: 'PaginationService',
        error: e,
        stackTrace: s,
      );
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
    pagingController.refresh();
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
