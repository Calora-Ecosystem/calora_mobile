import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/language%20/select/management/select_language_management.dart';
import 'package:calora/presentation/language%20/select/management/select_language_manager.dart';
import 'package:calora/widgets/builder/language_item_builder.dart';
import 'package:calora/widgets/language/language_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class SelectLanguagePage
    extends
        Managed<
          SelectLanguageManager,
          SelectLanguageState,
          SelectLanguageEffect
        > {
  const SelectLanguagePage({super.key});

  @override
  void init(context, manager) {
    manager.getSelectedLanguage();
  }

  @override
  void listener(context, manager, effect) {}

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Assets.icons.background.image(fit: BoxFit.fill),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(),
                    Assets.icons.iconCalora.svg(),
                    const SizedBox(height: 32),
                    LanguageWidget(
                      languages: manager.state.languages,
                      selectedLanguage: manager.state.selectedLanguage,
                      onLanguageSelected: (data) {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
