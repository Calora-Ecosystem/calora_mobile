import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

/// A player that holds, or is queued for, one of the [_DecoderSlots].
abstract class _SlotClient {
  /// Prominent players (a detail sheet, a full-width paywall preview)
  /// may bump a thumbnail off its slot; thumbnails never bump anyone.
  bool get wantsPriority;

  /// A decoder is yours — start playing.
  void onSlotGranted();

  /// Your decoder went to a player that needs it more — stop and give
  /// it up. You keep your place at the front of the queue.
  void onSlotRevoked();
}

/// Global cap on how many [VideoPlayerController]s may exist at once.
///
/// Android hands out a small, device-dependent pool of hardware video
/// decoders (`MediaCodec`). Blowing past it does not throw a catchable
/// Dart error — it aborts the process natively. An exercise list that
/// mounted one auto-playing MP4 preview per row did exactly that the
/// moment it appeared, so no player may touch a controller before it
/// owns a slot here.
///
/// Slots go out first-come-first-served, which for a lazily-built list
/// means the rows nearest the top of the viewport are the ones that
/// animate. Scrolling disposes off-screen rows, freeing their slots for
/// the rows scrolling in.
class _DecoderSlots {
  _DecoderSlots._();

  /// Deliberately conservative — the pool is shared with every other
  /// app on the device, and list previews are 64px thumbnails.
  static const int maxConcurrent = 4;

  static final List<_SlotClient> _holders = <_SlotClient>[];
  static final List<_SlotClient> _waiting = <_SlotClient>[];

  /// Asks for a decoder. Grants one immediately when the budget allows,
  /// or when [_SlotClient.wantsPriority] lets the caller take one from a
  /// thumbnail. Otherwise the caller is queued and must render a static
  /// placeholder until [_SlotClient.onSlotGranted] fires.
  static void request(_SlotClient client) {
    if (_holders.contains(client) || _waiting.contains(client)) return;

    if (_holders.length < maxConcurrent) {
      _grant(client);
      return;
    }

    if (client.wantsPriority) {
      final index = _holders.indexWhere((holder) => !holder.wantsPriority);
      if (index != -1) {
        final evicted = _holders.removeAt(index);
        evicted.onSlotRevoked();
        _waiting.insert(0, evicted); // first to get one back
        _grant(client);
        return;
      }
    }

    _waiting.add(client);
  }

  /// Gives back a held slot, or withdraws a queued request. Safe to call
  /// for a client that holds neither.
  static void release(_SlotClient client) {
    _waiting.remove(client);
    if (!_holders.remove(client)) return;
    while (_holders.length < maxConcurrent && _waiting.isNotEmpty) {
      _grant(_waiting.removeAt(0));
    }
  }

  static void _grant(_SlotClient client) {
    _holders.add(client);
    client.onSlotGranted();
  }
}

/// Renders an MP4 as a looping, muted, auto-playing "GIF".
///
/// Lifecycle
/// ─────────
/// * `initState`     — requests a decoder slot; on success creates the
///                     controller, kicks off async init, mutes the
///                     volume, enables looping, and starts playback as
///                     soon as the first frame is ready. Without a slot
///                     it shows a static tile and waits its turn.
/// * `didUpdateWidget` — if [url] changes, the old controller is
///                       disposed and a new one is created (keeping the
///                       slot, if this player holds one).
/// * `dispose`       — releases the controller *and* the slot, handing
///                     the slot to whichever player is next in line.
///
/// While the controller is initializing the widget shows a shimmer
/// placeholder; on a load failure it falls back to a static icon so
/// the surrounding layout never collapses.
class LoopingMutedVideoPlayer extends StatefulWidget {
  /// Absolute URL of the source video. Pass `null` to render the
  /// fallback icon (e.g. when the asset is missing from the API
  /// payload).
  final String? url;

  /// Logical height of the playback area. The video is centered and
  /// covered (`BoxFit.cover`) so different aspect ratios crop rather
  /// than letterbox.
  final double height;

  /// Corner radius for the clip mask around the video.
  final double borderRadius;

  /// Set for a single prominent player — a detail sheet, the workout
  /// runner, a full-width paywall preview — so it can claim a decoder
  /// from the list thumbnails still mounted behind it. Leave false for
  /// anything rendered per-row.
  final bool priority;

  const LoopingMutedVideoPlayer({
    super.key,
    required this.url,
    this.height = 120,
    this.borderRadius = 16,
    this.priority = false,
  });

  @override
  State<LoopingMutedVideoPlayer> createState() =>
      _LoopingMutedVideoPlayerState();
}

class _LoopingMutedVideoPlayerState extends State<LoopingMutedVideoPlayer>
    implements _SlotClient {
  VideoPlayerController? _controller;
  bool _hasError = false;

  /// Whether this player currently owns one of the [_DecoderSlots].
  bool _hasSlot = false;

  @override
  bool get wantsPriority => widget.priority;

  @override
  void initState() {
    super.initState();
    _requestPlayback(widget.url);
  }

  @override
  void didUpdateWidget(covariant LoopingMutedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      if (_hasSlot) {
        // Already our turn — swap the source without giving it up.
        _initController(widget.url);
      } else {
        _DecoderSlots.release(this);
        _hasSlot = false;
        _requestPlayback(widget.url);
      }
    }
  }

  /// Enters the decoder queue for [url]. A missing URL never takes a
  /// slot — it has nothing to play.
  void _requestPlayback(String? url) {
    if (url == null || url.isEmpty) {
      _hasError = true;
      _controller = null;
      return;
    }
    _hasError = false;
    _DecoderSlots.request(this);
  }

  @override
  void onSlotGranted() {
    _hasSlot = true;
    if (!mounted) {
      // Handed a slot on the way out — give it straight back.
      _DecoderSlots.release(this);
      _hasSlot = false;
      return;
    }
    _initController(widget.url);
  }

  @override
  void onSlotRevoked() {
    _hasSlot = false;
    _disposeController();
    _scheduleRebuild();
  }

  /// Revocation can land mid-frame (a newly built player asking for a
  /// decoder while the list is laying out), where a bare `setState`
  /// would throw. Defer to the end of the frame in that case.
  void _scheduleRebuild() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  Future<void> _initController(String? url) async {
    if (url == null || url.isEmpty) {
      setState(() {
        _hasError = true;
        _controller = null;
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    try {
      await controller.initialize();
      // Disposed, or bumped off its slot, while the source loaded.
      if (!mounted || !_hasSlot || !identical(_controller, controller)) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      setState(() => _hasError = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.pause();
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    _DecoderSlots.release(this);
    _hasSlot = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final controller = _controller;

    // Over the decoder budget: a still tile, never a spinner that would
    // sit there until some other player happens to go away.
    final Widget child = _hasError || !_hasSlot
        ? _StaticTile(height: widget.height)
        : (controller == null || !controller.value.isInitialized)
            ? _Placeholder(height: widget.height)
            : FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              );

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: child,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double height;

  const _Placeholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      loading: true,
      type: ShimmerType.backgroundElevation,
      shimmerChild: ShimmerChild(height: height),
      child: const SizedBox.shrink(),
    );
  }
}

/// Non-animating stand-in, used both when the source failed to load and
/// when the player is waiting for a decoder slot.
class _StaticTile extends StatelessWidget {
  final double height;

  const _StaticTile({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: context.colors.backgroundElevation,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_filter_outlined,
        size: 32,
        color: context.colors.iconSoft,
      ),
    );
  }
}
