import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry DSN.
///
/// Public by design — a DSN is embedded in every shipped client and only
/// grants event ingestion, never read access. Kept in source so a build
/// without CI wiring still reports, but overridable so staging and
/// production can point at separate projects:
///
/// ```
/// flutter build appbundle --dart-define=SENTRY_DSN=https://…
/// ```
const _dsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue:
      'https://c9d44ea0965566c7fa6838a77b5d3bbb@o4511824772399104.ingest.de.sentry.io/4511876582801488',
);

/// Version identity of the build. Left empty by default, in which case the
/// native SDKs auto-detect from the platform package — set these in CI when
/// you want them to match your own versioning scheme exactly.
const _release = String.fromEnvironment('SENTRY_RELEASE');
const _dist = String.fromEnvironment('SENTRY_DIST');

/// Sample rates as whole percents, because Dart has no
/// `double.fromEnvironment`. All tunable per build without a code change.
const _tracesPercent = int.fromEnvironment('SENTRY_TRACES_PCT', defaultValue: 20);
// Defaults to 0 (healthy sessions are not recorded) — see below.
const _replaySessionPercent = int.fromEnvironment('SENTRY_REPLAY_SESSION_PCT');
const _replayErrorPercent = int.fromEnvironment(
  'SENTRY_REPLAY_ERROR_PCT',
  defaultValue: 100,
);

/// Production Sentry configuration, including Session Replay.
///
/// Applied from `SentryFlutter.init` in `main.dart`. Kept out of `main.dart`
/// so the privacy-relevant decisions live in one reviewable place — this is
/// a health app, and everything here is chosen on the assumption that any
/// pixel or string could be someone's weight, diet or medical detail.
void configureSentry(SentryFlutterOptions options) {
  // An empty DSN disables the SDK outright. Debug builds therefore never
  // reach the production project: hot-reload crashes, half-written widgets
  // and local experiments would otherwise drown real user errors and burn
  // quota. `DioSentryReporter` already self-guards the same way.
  options.dsn = kDebugMode ? '' : _dsn;
  options.debug = kDebugMode;
  options.environment = kReleaseMode ? 'production' : 'staging';

  if (_release.isNotEmpty) options.release = _release;
  if (_dist.isNotEmpty) options.dist = _dist;

  // Performance tracing was hard-disabled (0.0), so there was no latency or
  // slow-frame data at all. A sampled rate gives that back at bounded cost.
  options.tracesSampleRate = _tracesPercent / 100;

  // Never let the SDK attach usernames, emails or IP addresses on its own.
  // Anything genuinely needed for debugging should be added deliberately
  // and scrubbed, the way `DioSentryReporter` does it.
  options.sendDefaultPii = false;

  options.enableAutoSessionTracking = true;
  options.maxBreadcrumbs = 100;

  // ── Session Replay ────────────────────────────────────────────────────
  // A replay is a reconstructed video of the session. `onErrorSampleRate`
  // attaches the ~30s leading up to an error, which is the part worth
  // paying for; `sessionSampleRate` records healthy sessions too and is
  // off by default because it is billed per replay.
  options.experimental.replay.sessionSampleRate = _replaySessionPercent / 100;
  options.experimental.replay.onErrorSampleRate = _replayErrorPercent / 100;
  options.experimental.replay.quality = SentryReplayQuality.medium;

  // ── Masking ───────────────────────────────────────────────────────────
  // Set explicitly rather than relying on defaults, because the defaults
  // differ between replays (masked) and event screenshots (unmasked), and
  // because these values must not drift silently in a health app.
  //
  // Merely touching `options.experimental.privacy` is also what switches
  // screenshot masking on — so this block is a precondition for the
  // `attachScreenshot` below being safe.
  options.experimental.privacy
    // Weights, calorie targets and meal names are all Text widgets.
    ..maskAllText = true
    // Meal photos and profile pictures are Image widgets.
    ..maskAllImages = true
    // Bundled assets (icons, illustrations, backgrounds) carry no user
    // data, and leaving them visible is what keeps a masked replay
    // recognisable enough to debug.
    ..maskAssetImages = false;

  options.attachScreenshot = true;
  options.attachViewHierarchy = true;
}
