import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_subscription_order_model.freezed.dart';
part 'my_subscription_order_model.g.dart';

@freezed
sealed class MySubscriptionOrderModel with _$MySubscriptionOrderModel {
  const factory MySubscriptionOrderModel({
    int? id,
    String? status,
    int? amount,
    String? type,
    String? provider,
    String? createdAt,
    String? updatedAt,
  }) = _MySubscriptionOrderModel;

  factory MySubscriptionOrderModel.fromJson(Map<String, dynamic> json) =>
      _$MySubscriptionOrderModelFromJson(json);

  static List<MySubscriptionOrderModel> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(MySubscriptionOrderModel.fromJson)
        .toList();
  }
}

extension SubscriptionOrderStatus on MySubscriptionOrderModel {
  static const _closed = {
    'paid',
    'completed',
    'success',
    'succeeded',
    'cancelled',
    'canceled',
    'failed',
    'expired',
    'refunded',
    'rejected',
    'deleted',
  };

  String get _status => status?.trim().toLowerCase() ?? '';

  bool get isPending => _status == 'pending';

  bool get isOpen => !_closed.contains(_status);

  DateTime? get createdAtTime => DateTime.tryParse(createdAt ?? '');
}

extension SubscriptionOrders on Iterable<MySubscriptionOrderModel> {
  MySubscriptionOrderModel? get pending =>
      where((order) => order.isPending).newest ??
      where((order) => order.isOpen).newest;

  MySubscriptionOrderModel? get newest =>
      fold<MySubscriptionOrderModel?>(null, (newest, order) {
        final time = order.createdAtTime;
        final newestTime = newest?.createdAtTime;
        if (newest == null) return order;
        if (time == null || newestTime == null) return newest;
        return time.isAfter(newestTime) ? order : newest;
      });
}
