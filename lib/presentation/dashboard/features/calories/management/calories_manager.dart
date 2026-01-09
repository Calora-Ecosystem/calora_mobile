import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:calora/presentation/dashboard/features/calories/management/calories_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CaloriesManager extends Manager<CaloriesState, CaloriesEffect> {
  final CaloriesRepo repo;

  CaloriesManager(this.repo) : super(const CaloriesState());

  void setScrolled(bool value) {
    if (state.isScrolled != value) {
      emit(state.copyWith(isScrolled: value));
    }
  }

  void onBreakfastTap() => publish(
    CaloriesEffect.openMealPage(
      MealType.Breakfast,
      state.meals,
      state.date ?? DateTime.now(),
    ),
  );

  void onLunchTap() => publish(
    CaloriesEffect.openMealPage(
      MealType.Lunch,
      state.meals,
      state.date ?? DateTime.now(),
    ),
  );

  void onSnackTap() => publish(
    CaloriesEffect.openMealPage(
      MealType.Snack,
      state.meals,
      state.date ?? DateTime.now(),
    ),
  );

  void onDinnerTap() => publish(
    CaloriesEffect.openMealPage(
      MealType.Dinner,
      state.meals,
      state.date ?? DateTime.now(),
    ),
  );

  void fetchCaloriesAndMeals(DateTime date) {
    repo
        .fetchSummary(date)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (result) => emit(
            state.copyWith(
              plan: result.dailyCalories.plan,
              consumed: result.dailyCalories.consumed,
              leftover: result.dailyCalories.leftover,
              meals: result.meals,
              isLoading: false,
            ),
          ),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void getSummary(DateTime date) {}

  void dateTime(DateTime date) {
    emit(state.copyWith(date: date));
  }

  List<MealInfo> get meals {
    return [
      MealInfo(
        title: Strings.breakfast,
        value: state.meals.isNotEmpty
            ? state.meals[0].value.asFixedTruncated(0)
            : '0',
        max: state.meals.isNotEmpty
            ? state.meals[0].max.asFixedTruncated(0)
            : '0',
        image: Assets.images.breakfast.image(),
        onTap: onBreakfastTap,
      ),
      MealInfo(
        title: Strings.lunch,
        value: state.meals.length > 1
            ? state.meals[1].value.asFixedTruncated(0)
            : '0',
        max: state.meals.length > 1
            ? state.meals[1].max.asFixedTruncated(0)
            : '0',
        image: Assets.images.lunch.image(),
        onTap: onLunchTap,
      ),
      MealInfo(
        title: Strings.snacks,
        value: state.meals.length > 2
            ? state.meals[2].value.asFixedTruncated(0)
            : '0',
        max: state.meals.length > 2
            ? state.meals[2].max.asFixedTruncated(0)
            : '0',
        image: Assets.images.snacks.image(),
        onTap: onSnackTap,
      ),
      MealInfo(
        title: Strings.dinner,
        value: state.meals.length > 3
            ? state.meals[3].value.asFixedTruncated(0)
            : '0',
        max: state.meals.length > 3
            ? state.meals[3].max.asFixedTruncated(0)
            : '0',
        image: Assets.images.dinner.image(),
        onTap: onDinnerTap,
      ),
    ];
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}
