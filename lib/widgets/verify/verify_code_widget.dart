import 'dart:async';

import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyCodeWidget extends StatefulWidget {
  final Function(String) resultCode;
  final Function() resend;
  final bool isStartTime;

  VerifyCodeWidget({
    required this.resend,
    required this.resultCode,
    required this.isStartTime,
  });

  @override
  State<VerifyCodeWidget> createState() => _VerifyCodeWidgetState();
}

class _VerifyCodeWidgetState extends State<VerifyCodeWidget> {
  Duration _remainingTime = const Duration(minutes: 3, seconds: 0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isStartTime) {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _remainingTime.inSeconds == 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.backgroundBase,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1, color: context.colors.strokeSoft),
          ),
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            keyboardType: TextInputType.number,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            // Even spacing
            pinTheme: PinTheme(
              fieldHeight: 36,
              fieldWidth: 18,
              fieldOuterPadding: EdgeInsets.symmetric(
                vertical: 10,
              ),
              activeFillColor: context.colors.backgroundBase,
              activeColor: Colors.transparent,
              selectedFillColor: context.colors.backgroundBase,
              selectedColor: Colors.transparent,
              inactiveFillColor: context.colors.backgroundBase,
              inactiveColor: Colors.transparent,
            ),
            onCompleted: (data) {
              widget.resultCode(data);
            },
            hintCharacter: '-',
          ),
        ),
        SizedBox(height: 16), // Added spacing
        isActive
            ? InkWell(
                onTap: () {
                  widget.resend();
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Strings.resend
                      .text(14, 20, 500)
                      .c(context.colors.accentSub),
                ),
              )
            : Row(
                children: [
                  Strings.resend.text(14, 20, 500).c(context.colors.textSub),
                  SizedBox(width: 4),
                  "${_formatDuration(_remainingTime)} "
                      .text(14, 20, 500)
                      .c(context.colors.textStrong),
                ],
              ),
        SizedBox(height: 32), // Added spacing
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _handleResend() {
    if (_remainingTime.inSeconds == 0) {
      setState(() {
        _remainingTime = const Duration(minutes: 3, seconds: 0);
      });
      _startTimer();
    }
  }
}
