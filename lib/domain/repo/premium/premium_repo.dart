import 'package:calora/domain/model/premium/my_subscription_order_model.dart';

abstract class PremiumRepo {
  Future<String> orderSubscription({required String provider, required String plan, required int orderMonth});
  Future<void> deleteOrder({required int orderId});
  Future<String> getPaymentLink({required int orderId});
  Future<List<MySubscriptionOrderModel>> getMyOrders();
}
