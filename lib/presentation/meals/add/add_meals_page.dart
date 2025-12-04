import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/speech/speech_page.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/creator/food_creator.dart';
import 'package:calora/widgets/meals/meals_type_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/add_meals_management.dart';
import 'management/add_meals_manager.dart';

@RoutePage()
class AddMealsPage extends Managed<AddMealsManager, AddMealsState, AddMealsEffect> {
  const AddMealsPage({super.key});

  @override
  void listener(BuildContext context, AddMealsManager manager, AddMealsEffect effect) {
    super.listener(context, manager, effect);
    effect.mapOrNull(openDishesPage: (e) => context.pushRoute(DishesRoute(mealCategory: e.category)));
  }

  @override
  Widget builder(BuildContext context, AddMealsManager manager, AddMealsState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: Strings.add),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            spacing: 12,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: Strings.searchForFoodOrProduct,
                  hintStyle: TextStyle(
                    color: context.colors.textSub,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 0.8,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.strokeSoft, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.blue, width: 1.5),
                  ),
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  buildActionCard(
                    onTap: () => openCreatePage(context),
                    context: context,
                    icon: Assets.icons.icPlusCircle.svg(),
                    text: Strings.creation,
                    textColor: context.colors.textStrong,
                  ),
                  buildActionCard(
                    onTap: () => openCameraPage(context),
                    context: context,
                    icon: Assets.icons.icScan.svg(),
                    text: Strings.scanning,
                    textColor: context.colors.textWhite,
                    useGradient: true,
                  ),
                  buildActionCard(
                    onTap: () => openSpeechPage(context),
                    context: context,
                    icon: Assets.icons.icChat.svg(),
                    text: Strings.byVoice,
                    textColor: context.colors.textWhite,
                    useGradient: true,
                  ),
                ],
              ),
              Expanded(
                child: MealTypeGrid(
                  onMealTypeSelected: (category) => manager.openDishesPage(category),
                  mealTypes: manager.mealTypes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openCreatePage(BuildContext context) {
    context.showAppBottomSheet(
      child: FoodCreatorWidget(),
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.5,
    );
  }

  void openSpeechPage(BuildContext context) {
    context.showAppBottomSheet(
      initialChildSize: 0.5,
      minChildSize: 0.2,
      maxChildSize: 0.5,
      child: ModernVoiceRecorder(
        onFinished: (value) => context.pushRoute(
          UniversalProgressRoute(
            onComplete: () => context.replaceRoute(AddMealsRoute()),
            description: Strings.theInformationInYourVoicemailIsBeingAnalyzed,
            title: Strings.addByVoice,
            steps: [
              Strings.theCompositionOfTheFoodIsBeingDetermined,
              Strings.theAmountOfFoodIsMeasured,
              Strings.theCalorieContentOfTheFoodIsBeingMeasured,
            ],
          ),
        ),
      ),
    );
  }

  void openCameraPage(BuildContext context) {
    context.pushRoute(
      UniversalCameraRoute(
        title: Strings.scanning,
        subtitle: Strings.placeTheFoodInTheDesignatedAreaAndTakeAPicture,
        bottomText: Strings.food,
        useFrontCamera: false,
        onImageCaptured: (value) => context.pushRoute(
          UniversalProgressRoute(
            onComplete: () => context.replaceRoute(AddMealsRoute()),
            description: Strings.theDataInTheImageIsBeingProcessedWeWillAnnounceTheResultsSoon,
            title: Strings.caloraAi,
            steps: [
              Strings.theCompositionOfTheFoodIsBeingDetermined,
              Strings.theAmountOfFoodIsMeasured,
              Strings.theCalorieContentOfTheFoodIsBeingMeasured,
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionCard({
    required BuildContext context,
    Widget? icon,
    required String text,
    Color? textColor,
    VoidCallback? onTap,
    bool useGradient = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: useGradient ? null : context.colors.backgroundElevation,
            gradient: useGradient
                ? RadialGradient(
                    center: const Alignment(1.2, 0.5),
                    radius: 1.3,
                    colors: [context.colors.honeydew, context.colors.mintGreen],
                    stops: const [0.0, 1.0],
                  )
                : null,
          ),
          child: Column(
            spacing: 8,
            children: [if (icon != null) icon, text.text(14, 16, 600).c(textColor ?? context.colors.textWhite)],
          ),
        ),
      ),
    );
  }
}
