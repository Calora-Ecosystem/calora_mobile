import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/promo_code_model.dart';
import 'package:calora/domain/model/premium/subscription_response_model.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class PremiumApi {
  final Dio _dio;

  PremiumApi(this._dio);

  Future<SubscriptionResponseModel> orderSubscription({
    required String provider,
    required String plan,
    required int orderMonth,
    int? couponId,
  }) async {
    final data = {'provider': provider, 'plan': plan, 'planExtraId': orderMonth, 'couponId': couponId};
    final response = await _dio.post('/billing/orders/subscription', data: data);
    final json = (response.data as Map<String, dynamic>)['content'];
    return SubscriptionResponseModel.fromJson(json);
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

  Future<List<PremiumPlanModel>> getPremiumPlans() async {
    final response = await _dio.get('/billing/orders/subscription/plans/Premium');
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>?;
    if (content == null) return [];
    return PremiumPlanModel.listFromJson(content);
  }

  Future<PromoCodeModel> getPromoCodeAmount({required String code}) async {
    try {
      final response = await _dio.get('/billing/coupons/check', queryParameters: {'code': code});
      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>?;
      if (content == null) return PromoCodeModel();
      return PromoCodeModel.fromJson(content);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return PromoCodeModel();
      rethrow;
    }
  }
}
