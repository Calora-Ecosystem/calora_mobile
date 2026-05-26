import 'package:auto_route/annotations.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/lessons/management/lessons_management.dart';
import 'package:calora/presentation/lessons/management/lessons_manager.dart';
import 'package:calora/widgets/app_bar/lesson_app_bar.dart';
import 'package:calora/widgets/lessons/lessons_cards.dart' show LessonsCards;
import 'package:calora/widgets/premium/premium_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class LessonsPage extends Managed<LessonsManager, LessonsState, LessonsEffect> {
  final int courseId;
  final String imageUrl;

  const LessonsPage({super.key, required this.courseId, required this.imageUrl});

  Level _mapIntToLevel(int index) {
    switch (index) {
      case 0:
        return Level.minimal;
      case 1:
        return Level.less;
      case 2:
        return Level.medium;
      case 3:
        return Level.high;
      case 4:
        return Level.maximal;
      default:
        return Level.minimal;
    }
  }

  @override
  void init(BuildContext context, LessonsManager manager) {
    manager.getWorkout(courseId);
    manager.loadActivityLevel();
    super.init(context, manager);
  }

  @override
  Widget builder(BuildContext context, LessonsManager manager, LessonsState state) {
    final bool isUserPremium = context.read<AppManager>().state.isUserPremium;

    final totalItems = state.workouts.fold(0, (sum, w) => sum + w.totalItems);
    final doneItems = state.workouts.fold(0, (sum, w) => sum + w.doneItems);
    final progressPercent = safePercent(done: doneItems, total: totalItems);

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
                child: ClipRect(
                  child: CustomCachedNetworkImage.banner(imageUrl: imageUrl),
                ),
              ),
            ),
          ),
          DefaultRefreshIndicator(
            onRefresh: () async {
              manager.getWorkout(courseId);
              manager.loadActivityLevel();
            },
            child: Column(
              children: [
                LessonAppBar(
                  percent: progressPercent,
                  title: Strings.changeWithin30Days,
                  level: _mapIntToLevel(state.levelIndex),
                  onLevelChanged: (value) => manager.changeActivityLevel(courseId, value),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (!isUserPremium) PremiumEntryCard(),
                          LessonsCards(
                            level: _mapIntToLevel(state.levelIndex),
                            isLoading: state.isLoading,
                            workouts: state.workouts,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double safePercent({
    required num done,
    required num total,
    double min = 0.0,
    double max = 1.0,
  }) {
    if (total <= 0) return min;

    final value = done / total;

    if (!value.isFinite || value.isNaN) return min;

    return value.clamp(min, max).toDouble();
  }
}
