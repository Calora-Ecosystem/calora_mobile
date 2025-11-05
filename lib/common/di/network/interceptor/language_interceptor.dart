import 'package:calora/data/store/common/common_store.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LanguageInterceptor extends Interceptor {
  final CommonStore commonStore;

  LanguageInterceptor(this.commonStore);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final result = await commonStore.language();
    options.headers['Accept-Language'] = result?.code ?? 'UZ';
    handler.next(options);
  }
}
