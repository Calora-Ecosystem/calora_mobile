import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.cover),
          ),
          Center(
            child: Strings.installTheNewVersion.text(24, 30, 500).copyWith(textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
