import 'package:calora/common/widgets/display/display.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ErrorInterceptor extends Interceptor {
  final Display display;

  ErrorInterceptor(this.display);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errors =
        (err.response?.data?['modelStateError'] ?? List.empty()) as List;
    if (errors.isNotEmpty) {
      display.error(errors.first['errorMessage']);
    }
    handler.next(err);
  }
}
