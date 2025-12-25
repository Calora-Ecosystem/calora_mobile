import 'dart:developer';

import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ModernVoiceRecorder extends StatefulWidget {
  final ValueChanged<String> onFinished;

  const ModernVoiceRecorder({super.key, required this.onFinished});

  @override
  State<ModernVoiceRecorder> createState() => _ModernVoiceRecorderState();
}

class _ModernVoiceRecorderState extends State<ModernVoiceRecorder> {
  late AudioRecorder _recorder;
  late AudioPlayer _player;
  bool _isRecording = false;

  String? _filePath;

  int _seconds = 0;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _player = AudioPlayer();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _filePath = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(), path: _filePath!);
      _seconds = 0;
      _stopwatch.reset();
      _stopwatch.start();

      _tickTimer();

      setState(() => _isRecording = true);
    }
  }

  void _tickTimer() async {
    while (_stopwatch.isRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_stopwatch.isRunning) break;
      setState(() => _seconds = _stopwatch.elapsed.inSeconds);
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    _stopwatch.stop();

    setState(() {
      _isRecording = false;
    });

    if (_filePath != null) widget.onFinished(_filePath!);
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 20,
        children: [
          SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: context.colors.backgroundElevation, shape: BoxShape.circle),
            child: !_isRecording
                ? Assets.icons.icMicro.svg()
                : Column(
                    children: [
                      Assets.icons.icWriteSpeech.svg(),
                      SizedBox(height: 8),
                      _formatTime(_seconds).text(20, 24, 600).c(context.colors.textStrong),
                    ],
                  ),
          ),
          const SizedBox(height: 30),
          Strings.tellMeWhatYouAteSaySomethingLikeCoffee300GramsOfWhiteBread3Eggs
              .text(14, 16, 400)
              .c(context.colors.textStrong)
              .copyWith(textAlign: TextAlign.center),
          SizedBox(
            width: double.infinity,
            child: Button(
              text: Strings.continueBtn,
              onPressed: () {
                log('OnClickSpeech');
                if (_isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
