/// Keys for Dio's `RequestOptions.extra` map used to tweak interceptor
/// behaviour on a per-request basis.

/// Set to `true` on a request whose caller shows its own error UI (e.g. a
/// page-level SnackBar). [ErrorInterceptor] then skips the app-wide error
/// display for that request so the user doesn't see the same message twice.
const String kSkipGlobalErrorDisplay = 'skipGlobalErrorDisplay';
