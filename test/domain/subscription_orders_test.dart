import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MySubscriptionOrderModel order(int id, String? status, [String? createdAt]) =>
      MySubscriptionOrderModel(id: id, status: status, createdAt: createdAt);

  test('finished orders are never pending', () {
    final orders = [
      for (final status in ['Paid', 'completed', 'Cancelled', 'FAILED'])
        order(1, status),
    ];
    expect(orders.pending, isNull);
  });

  test('the newest pending order wins', () {
    final orders = [
      order(1, 'Pending', '2026-10-01T10:00:00'),
      order(2, 'Pending', '2026-10-03T10:00:00'),
      order(3, 'Paid', '2026-10-04T10:00:00'),
    ];
    expect(orders.pending?.id, 2);
  });

  test('an explicit pending order beats one with an unknown status', () {
    final orders = [
      order(1, 'Pending', '2026-10-01T10:00:00'),
      order(2, null, '2026-10-05T10:00:00'),
    ];
    expect(orders.pending?.id, 1);
  });

  test('an order with an unknown status still counts as open', () {
    expect([order(7, 'Created'), order(8, 'Paid')].pending?.id, 7);
  });

  test('without dates the server order is kept', () {
    expect([order(4, 'Pending'), order(5, 'Pending')].pending?.id, 4);
  });
}
