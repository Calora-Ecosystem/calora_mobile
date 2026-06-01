import 'dart:async';
import 'dart:io';

import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Inline YouTube player with a guaranteed "Open in YouTube" escape
/// hatch beneath it.
///
/// Why an always-visible CTA
/// ─────────────────────────
/// YouTube's iframe player rejects some videos with a built-in
/// "Video unavailable" frame (error codes 101 / 150 / 152 / etc.).
/// The cause varies — uploader-disabled embedding, age gating, regional
/// rules, WebView-specific cookie context — and **the failure isn't
/// always surfaced to the JS host**: code 152 in particular renders
/// the error overlay without firing the `onError` postMessage, so a
/// stream-listener fallback can't catch it.
///
/// Detection from outside the iframe is also unreliable: YouTube's
/// oEmbed endpoint and the watch page's `playabilityStatus` both
/// return "embeddable" for many videos that the iframe still refuses
/// to play. So instead of guessing, we always render a small
/// "Open in YouTube" link below the player. If the embed works, it
/// plays inline; if it shows YouTube's error frame, the user has an
/// obvious one-tap path to the working watch page.
///
/// We still pre-check oEmbed for the clearly-broken cases (`401`
/// embed-disabled, `404` removed) so those videos skip the iframe
/// entirely and go straight to a full fallback card, and keep the
/// stream listener as belt-and-suspenders for restriction errors
/// that *do* report up to JS.
class YoutubeInlinePlayer extends StatefulWidget {
  final String youtubeUrl;

  const YoutubeInlinePlayer({super.key, required this.youtubeUrl});

  @override
  State<YoutubeInlinePlayer> createState() => _YoutubeInlinePlayerState();
}

class _YoutubeInlinePlayerState extends State<YoutubeInlinePlayer> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;
  bool _embedBlocked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final id = _extractYoutubeId(widget.youtubeUrl);
    if (id == null) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final embeddable = await _checkEmbeddable(widget.youtubeUrl);
    if (!mounted) return;

    if (!embeddable) {
      setState(() {
        _embedBlocked = true;
        _checking = false;
      });
      return;
    }

    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    _controller = controller;

    _sub = controller.stream.listen((value) {
      if (value.error != YoutubeError.none &&
          value.error != YoutubeError.unknown &&
          !_embedBlocked &&
          mounted) {
        setState(() => _embedBlocked = true);
      }
    });

    controller.loadVideoById(videoId: id);
    controller.pauseVideo();
    setState(() => _checking = false);
  }

  /// GET YouTube's oEmbed endpoint. Returns false for the deterministic
  /// "not embeddable" responses (401, 404). Anything else — including
  /// the 200 case where the iframe still fails — passes through; we'll
  /// rely on the always-visible CTA for those.
  Future<bool> _checkEmbeddable(String watchUrl) async {
    final oembed = Uri.https('www.youtube.com', '/oembed', {
      'url': watchUrl,
      'format': 'json',
    });

    final client = HttpClient();
    try {
      final req = await client
          .getUrl(oembed)
          .timeout(const Duration(seconds: 4));
      final res = await req.close().timeout(const Duration(seconds: 4));
      await res.drain<void>();
      // 401 → uploader disabled embedding. 404 → removed / private.
      if (res.statusCode == 401 || res.statusCode == 404) return false;
      return true;
    } catch (_) {
      return true;
    } finally {
      client.close(force: true);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _extractYoutubeId(widget.youtubeUrl);
    if (id == null) {
      return _Fallback(
        message: Strings.youtubeLinkInvalid,
        canOpen: false,
        onOpen: null,
      );
    }

    if (_checking) {
      return const _CheckingPlaceholder();
    }

    if (_embedBlocked || _controller == null) {
      return _Fallback(
        message: Strings.youtubeInlineBlocked,
        canOpen: true,
        onOpen: () => _openExternally(widget.youtubeUrl),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(controller: _controller!),
          ),
        ),
        const SizedBox(height: 6),
        _OpenOnYoutubeLink(onTap: () => _openExternally(widget.youtubeUrl)),
      ],
    );
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;

    final i = uri.pathSegments.indexOf('shorts');
    if (i != -1 && uri.pathSegments.length > i + 1) return uri.pathSegments[i + 1];

    final e = uri.pathSegments.indexOf('embed');
    if (e != -1 && uri.pathSegments.length > e + 1) return uri.pathSegments[e + 1];

    return null;
  }
}

class _OpenOnYoutubeLink extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenOnYoutubeLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.open_in_new,
                size: 16,
                color: context.colors.accentSub,
              ),
              const SizedBox(width: 6),
              Text(
                Strings.openInYoutube,
                style: TextStyle(
                  fontSize: 13,
                  height: 16 / 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.accentSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckingPlaceholder extends StatelessWidget {
  const _CheckingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: context.colors.backgroundElevation,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String message;
  final bool canOpen;
  final VoidCallback? onOpen;

  const _Fallback({
    required this.message,
    required this.canOpen,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: context.colors.backgroundElevation,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_display_outlined,
                size: 36,
                color: context.colors.iconSoft,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  color: context.colors.textSub,
                ),
              ),
              if (canOpen) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(Strings.openInYoutube),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
