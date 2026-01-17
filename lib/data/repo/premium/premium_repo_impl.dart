import 'package:calora/data/api/premium_api.dart';
import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: PremiumRepo)
class PremiumRepoImpl implements PremiumRepo {
  final PremiumApi _api;

  PremiumRepoImpl(this._api);

  @override
  Future<void> deleteOrder({required int orderId}) async {
    return await _api.deleteOrder(orderId: orderId);
  }

  @override
  Future<List<MySubscriptionOrderModel>> getMyOrders() async {
    return await _api.getMyOrders();
  }

  @override
  Future<String> getPaymentLink({required int orderId}) async {
    return await _api.getPaymentLink(orderId: orderId);
  }

  @override
  Future<String> orderSubscription({required String provider, required String plan, required int orderMonth}) async {
    return await _api.orderSubscription(provider: provider, plan: plan, orderMonth: orderMonth);
  }
}
