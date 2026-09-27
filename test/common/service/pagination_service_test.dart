import 'dart:async';

import 'package:calora/common/service/pagination_service.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drops a response that lands after refresh (tab switch)', () async {
    final pending = <Completer<PaginatedResponse<String>>>[];
    final service = PaginationService<String>(
      fetchData: (PaginationQuery _) {
        final c = Completer<PaginatedResponse<String>>();
        pending.add(c);
        return c.future;
      },
    );

    // Old tab starts loading, then the user switches tab before it returns.
    service.pagingController.notifyPageRequestListeners(0);
    service.refresh();
    service.pagingController.notifyPageRequestListeners(0);
    expect(pending, hasLength(2));

    // New tab answers first, then the stale response from the old tab.
    pending[1].complete(
      const PaginatedResponse<String>(content: ['latest'], total: 1),
    );
    await pumpEventQueue();
    pending[0].complete(
      const PaginatedResponse<String>(content: ['stale'], total: 1),
    );
    await pumpEventQueue();

    expect(service.pagingController.itemList, ['latest']);
    service.dispose();
  });
}
