import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/presentation/ai/ai_calculate/management/calora_ai_calculate_management.dart';
import 'package:calora/presentation/ai/ai_calculate/management/calora_ai_calculate_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:screenshot/screenshot.dart';

@RoutePage()
class CaloraAiCalculatePage
    extends
        Managed<
          CaloraAiCalculateManager,
          CaloraAiCalculateState,
          CaloraAiCalculateEffect
        > {
  final String imagePath;

  CaloraAiCalculatePage({super.key, required this.imagePath});

  final screenshotController = ScreenshotController();

  @override
  void init(BuildContext context, CaloraAiCalculateManager manager) {
    super.init(context, manager);
    manager.analyzeFace(imagePath);
  }

  @override
  void listener(
    BuildContext context,
    CaloraAiCalculateManager manager,
    CaloraAiCalculateEffect effect,
  ) {
    effect.when(
      error: (message) => CustomSnackBar.show(context, message),
      analysisComplete: () {},
    );
  }

  @override
  Widget builder(
    BuildContext context,
    CaloraAiCalculateManager manager,
    CaloraAiCalculateState state,
  ) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        backgroundColor: context.colors.white,
        appBar: CustomAppBar(
          title: Strings.caloraAi
              .text(16, 20, 500)
              .c(context.colors.textStrong),
          onBack: () => _onBack(context),
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: context.colors.white,
            border: Border(top: BorderSide(color: context.colors.strokeSoft)),
          ),
          child: AnimatedCrossFade(
            firstChild: _buildAnalyzingView(context, manager, state),
            secondChild: _buildCompletedView(context, manager, state),
            crossFadeState: !state.isCompleted
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ),
        bottomNavigationBar: (state.isCompleted && state.errorMessage == null)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Button(
                      text: Strings.share,
                      loading: state.isSharing,
                      onPressed: state.isSharing
                          ? null
                          : () => manager.shareResults(screenshotController),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    CaloraAiCalculateManager manager,
    CaloraAiCalculateState state,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context, Strings.bodyAnalysis),
          const SizedBox(height: 20),
          _buildPercentCircle(
            context,
            percent: state.finalScore / 100,
            color: _getScoreColor(context, state.finalScore),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                '${state.finalScore}'
                    .text(32, 40, 700)
                    .c(_getScoreColor(context, state.finalScore)),
                '/100'
                    .text(14, 18, 400)
                    .c(_getScoreColor(context, state.finalScore)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Strings.yourPhysicalHealthLevel
              .text(14, 18, 400)
              .c(context.colors.textSub),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.analysisItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = state.analysisItems[index];
              return _infoItem(
                context,
                icon: item.iconPath,
                text: item.description,
                trailing: _buildTag(
                  context,
                  '${item.percentage}%',
                  context.colors.accentSub,
                  context.colors.paleGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView(
    BuildContext context,
    CaloraAiCalculateManager manager,
    CaloraAiCalculateState state,
  ) {
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            _buildHeader(context, Strings.caloraAi),
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSub, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Button(
              onPressed: () => context.router.maybePop(),
              text: Strings.tryAgain,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        _buildHeader(context, Strings.caloraAi),
        _infoItem(
          context,
          icon: Assets.icons.informationCircleBlue.svg(),
          text: Strings.analyzingYourPhoto,
          bgColor: context.colors.backgroundElevation,
          textColor: context.colors.brightBlue,
        ),
        _buildPercentCircle(
          context,
          percent: state.progressPercent,
          color: context.colors.accentSub,
          center: '${(state.progressPercent * 100).round()}%'
              .text(32, 40, 700)
              .c(context.colors.textStrong),
        ),
        ...[
          [Strings.yourFacialFeaturesAreBeingAnalyzed, 0.3],
          [Strings.theThingsYourEyesAnalyzed, 0.5],
          [Strings.additionalInformationIsBeingAnalyzed, 0.8],
        ].map((item) {
          final text = item[0] as String;
          final threshold = item[1] as double;
          final done = state.progressPercent >= threshold;
          return _infoItem(
            context,
            icon: done
                ? Assets.icons.done.svg()
                : const CupertinoActivityIndicator(radius: 12),
            text: text,
            bgColor: context.colors.commonBackground,
            textColor: done
                ? context.colors.textSub
                : context.colors.textStrong,
          );
        }),
      ],
    );
  }

  Widget _infoItem(
    BuildContext context, {
    required Widget icon,
    required String text,
    Color? bgColor,
    Color? textColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor ?? context.colors.commonBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 8,
        children: [
          icon,
          Expanded(
            child: text
                .text(14, 16, 400)
                .c(textColor ?? context.colors.textSub),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Column(
      children: [
        SizedBox(height: 100, width: 100, child: Assets.images.ai.image()),
        title.text(16, 20, 500).c(context.colors.textStrong),
      ],
    );
  }

  Widget _buildPercentCircle(
    BuildContext context, {
    required double percent,
    required Color color,
    required Widget center,
  }) {
    return Center(
      child: CircularPercentIndicator(
        radius: 80,
        lineWidth: 16,
        percent: percent.clamp(0, 1),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: color,
        backgroundColor: context.colors.backgroundElevation,
        center: center,
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: text.text(12, 14, 500).c(textColor),
    );
  }

  Color _getScoreColor(BuildContext context, int score) {
    if (score >= 80) return context.colors.accentSub;
    if (score >= 50) return context.colors.warningBase;
    return context.colors.errorBase;
  }

  void _onBack(BuildContext context) => context.router.pop();
}
