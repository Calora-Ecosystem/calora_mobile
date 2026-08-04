import 'package:calora/common/constants/request_extras.dart';
import 'package:calora/common/di/network/interceptor/dio_sentry_reporter.dart';
import 'package:calora/common/widgets/display/display.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ErrorInterceptor extends Interceptor {
  final Display display;

  ErrorInterceptor(this.display);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Telemetry: report the failure (scrubbed, filtered, grouped) to Sentry for
    // production debugging. Independent of the user-facing display below, and
    // of the caller's display opt-out.
    DioSentryReporter.report(err);

    // Callers that render their own error UI opt out of the app-wide display
    // so the same message isn't shown twice.
    final skipDisplay = err.requestOptions.extra[kSkipGlobalErrorDisplay] == true;

    if (!skipDisplay) {
      final errors =
          (err.response?.data?['modelStateError'] ?? List.empty()) as List;
      if (errors.isNotEmpty) {
        display.error(errors.first['errorMessage']);
      }
    }
    handler.next(err);
  }
}
