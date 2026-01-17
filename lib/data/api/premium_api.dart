import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class PremiumApi {
  final Dio _dio;

  PremiumApi(this._dio);

  Future<String> orderSubscription({required String provider, required String plan, required int orderMonth}) async {
    final data = {'provider': provider, 'plan': plan, 'planExtraId': orderMonth};
    final response = await _dio.post('/billing/orders/subscription', data: data);
    return (response.data as Map<String, dynamic>)['content'] as String;
  }

  Future<void> deleteOrder({required int orderId}) async {
    await _dio.delete('/billing/orders/$orderId');
  }

  Future<String> getPaymentLink({required int orderId}) async {
    final response = await _dio.get('/billing/orders/$orderId/payment-link');
    return (response.data as Map<String, dynamic>)['content'] as String;
  }

  Future<List<MySubscriptionOrderModel>> getMyOrders() async {
    final response = await _dio.get('/billing/orders/my');
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>?;
    if (content == null) return [];
    return MySubscriptionOrderModel.listFromJson(content);
  }
}
