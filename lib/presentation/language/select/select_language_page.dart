import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/language/select/management/select_language_management.dart';
import 'package:calora/presentation/language/select/management/select_language_manager.dart';
import 'package:calora/widgets/language/language_widget.dart';
import 'package:easy_localization/easy_localization.dart';
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Assets.icons.iconCalora.svg(),
                    SizedBox(height: 64),
                    Strings.selectLanguage.text(16, 20, 500),
                    SizedBox(height: 16),
                    LanguageWidget(
                      languages: manager.state.languages,
                      selectedLanguage: manager.state.selectedLanguage,
                      onLanguageSelected: (data) {
                        _saveSelectedLanguage(data, context, manager);
                      },
                    ),
                    SizedBox(height: 64),
                    SizedBox(
                      width: double.infinity,
                      child: Button(
                        onPressed: () => _openOnboarding(context),
                        child: Strings.doContinue
                            .text(16, 20, 500)
                            .c(context.colors.textWhite),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSelectedLanguage(Language language, BuildContext context, manager) {
    manager.setSelectedLanguage(language);
    EasyLocalization.of(context)?.setLocale(language.locale);
  }

  void _openOnboarding(BuildContext context) {
    context.router.replace(OnboardingRoute());
    context.read<SelectLanguageManager>().setLanguageSelectedFlag();
  }
}
