import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/extensions/build_context_extensions.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/sheets/default_bottom_sheet.dart';
import 'package:calora/presentation/app/connectivity/management/connectivity_management.dart';
import 'package:calora/presentation/app/connectivity/management/connectivity_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class ConnectivityLostSheet extends StatelessWidget {
  const ConnectivityLostSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.read<ConnectivityManager>();
    return ManagerBuilder<ConnectivityState, ConnectivityEffect>(
      manager: manager,
      properties: (state) => [
        state.connectionQuality,
        state.isLoading,
        state.isError,
        state.isLoading,
        state.isConnected,
      ],
      builder: (context, state) {
        return PopScope(
          canPop: state.isConnected,
          child: SizedBox(
            height: 350,
            child: DefaultBottomSheet(
              padding: EdgeInsets.zero,
              height: context.screenHeight,
              showHandle: false,
              child: Stack(
                children: [
                  Container(height: 350),
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    bottom: context.bottomPadding + 30,
                    child: Align(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final double width = constraints.maxWidth.clamp(100, 180);
                              return Assets.icons.offlineTRex.svg(width: width);
                            },
                          ),
                          const SizedBox(height: 32),
                          (state.hasInterface ? Strings.limitedInternetTitle : Strings.noInternetTitle)
                              .text(22, 24, 600)
                              .c(context.colors.textPrimary)
                              .copyWith(textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: (state.hasInterface ? Strings.limitedInternetSubtitle : Strings.noInternetSubtitle)
                                .text(16, 20, 500)
                                .c(context.colors.textSub)
                                .copyWith(textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: state.hasInterface,
                    child: Positioned(
                      left: 24,
                      right: 24,
                      bottom: context.bottomPadding + 20,
                      child: Button(
                        text: Strings.tryAgain,
                        loading: state.isLoading,
                        onPressed: manager.retry,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
