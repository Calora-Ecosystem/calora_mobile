import 'package:auto_route/annotations.dart';
import 'package:calora/common/base/gender_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/lessons/management/lessons_management.dart';
import 'package:calora/presentation/lessons/management/lessons_manager.dart';
import 'package:calora/widgets/app_bar/lesson_app_bar.dart';
import 'package:calora/widgets/lessons/lessons_cards.dart' show LessonsCards;
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class LessonsPage extends Managed<LessonsManager, LessonsState, LessonsEffect> {
  const LessonsPage({super.key});

  Level _mapIntToLevel(int index) {
    switch (index) {
      case 0:
        return Level.easy;
      case 1:
        return Level.withoutOverload;
      case 2:
        return Level.returnToActivity;
      case 3:
        return Level.increaseActivity;
      case 4:
        return Level.high;
      default:
        return Level.easy;
    }
  }

  @override
  void init(context, manager) {
    manager.getLessons();
  }

  @override
  Widget builder(BuildContext context, LessonsManager manager, LessonsState state) {
    return StreamBuilder<Gender>(
      stream: genderStore.watch(), // Genderdagi o‘zgarishlarni kuzatamiz
      builder: (context, snapshot) {
        final gender = snapshot.data ?? Gender.Male;

        return Scaffold(
          backgroundColor: context.colors.accentDisabled,
          body: Stack(
            children: [
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: gender == Gender.Female
                        ? Assets.images.femaleCourseImage.image(fit: BoxFit.cover)
                        : Assets.images.courseImage.image(fit: BoxFit.cover),
                  ),
                ),
              ),
              Column(
                children: [
                  LessonAppBar(
                    title: Strings.changeWithin30Days,
                    level: _mapIntToLevel(state.levelIndex),
                    onLevelChanged: (value) => manager.setLevel(value),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Assets.images.yandexBanner.image(),
                          LessonsCards(
                            lessons: state.lessons,
                            level: _mapIntToLevel(state.levelIndex),
                            gender: gender,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
