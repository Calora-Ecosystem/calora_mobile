
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LanguageInterceptor extends Interceptor {
  CommonStore commonStore;

  LanguageInterceptor(this.commonStore);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final result = await commonStore.language.call();
    options.headers['Accept-Language'] = result ?? Language.UZ;
    handler.next(options);
  }
}
