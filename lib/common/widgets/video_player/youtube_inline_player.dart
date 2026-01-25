import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeInlinePlayer extends StatefulWidget {
  final String youtubeUrl;

  const YoutubeInlinePlayer({super.key, required this.youtubeUrl});

  @override
  State<YoutubeInlinePlayer> createState() => _YoutubeInlinePlayerState();
}

class _YoutubeInlinePlayerState extends State<YoutubeInlinePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    final id = _extractYoutubeId(widget.youtubeUrl) ?? '';
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );

    if (id.isNotEmpty) {
      _controller.loadVideoById(videoId: id);
      _controller.pauseVideo(); // ochilishi bilan autoplay bo'lmasin
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _extractYoutubeId(widget.youtubeUrl);
    if (id == null) {
      return const SizedBox(height: 200, child: Center(child: Text('YouTube link noto‘g‘ri')));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(controller: _controller),
      ),
    );
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
