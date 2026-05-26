import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = Language.fromLocale(context.locale);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 24,
              height: 3,
              color: context.colors.strokeSoft,
            ),
          ),
          const SizedBox(height: 13),
          Strings.applicationLanguage.text(20, 24, 700),
          const SizedBox(height: 16),
          ...Language.values.map((lang) {
            final isSelected = lang == current;
            return ListTile(
              leading: lang.flag,
              title: lang.name.text(16, 20, 400),
              trailing: isSelected ? Assets.icons.icSingleCheck.svg() : null,
              onTap: () async {
                if (isSelected) return;
                // Persist for the TokenInterceptor (sets Accept-Language on
                // every request). Without this the header stays on the
                // previous language and the server keeps returning the old
                // locale for course/food/etc. content.
                getIt<CommonRepo>().setSelectedLanguage(lang);
                // Update EasyLocalization so Strings.* re-translate.
                await context.setLocale(lang.locale);
                if (!context.mounted) return;
                // Bump AppState.language so the DisplayWidget's ValueKey
                // changes, rebuilding the whole navigator subtree. That
                // causes every page's init() to fire again and refetch
                // server-localized data (e.g. course list).
                context.read<AppManager>().select(lang);
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
    );
  }
}
