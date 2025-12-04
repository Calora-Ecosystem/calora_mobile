import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:calora/presentation/dashboard/features/calories/management/calories_management.dart';
import 'package:calora/widgets/caloriya/meal_cards_grid.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CaloriesManager extends Manager<CaloriesState, CaloriesEffect> {
  final CaloriesRepo repo;

  List<MealInfo>? _mealsCache;
  List<MealData>? _lastStateMeals;

  CaloriesManager(this.repo) : super(const CaloriesState());

  void setScrolled(bool value) {
    if (state.isScrolled != value) {
      emit(state.copyWith(isScrolled: value));
    }
  }

  void onBreakfastTap() {
    publish(CaloriesEffect.openMealPage(MealType.breakfast));
  }

  void onLunchTap() {
    publish(CaloriesEffect.openMealPage(MealType.lunch));
  }

  void onSnackTap() {
    publish(CaloriesEffect.openMealPage(MealType.snacks));
  }

  void onDinnerTap() {
    publish(CaloriesEffect.openMealPage(MealType.dinner));
  }

  void getDailyCalories() {
    repo.getCalories().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(plan: data.plan, consumed: data.consumed, leftover: data.leftover)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  void getMealsData() {
    repo.getMeals().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(meals: data)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  List<MealInfo> get meals {
    if (_mealsCache != null && _lastStateMeals == state.meals) {
      return _mealsCache!;
    }

    _lastStateMeals = state.meals;
    _mealsCache = _buildMealsList();
    return _mealsCache!;
  }

  List<MealInfo> _buildMealsList() {
    return [
      MealInfo(
        title: Strings.breakfast,
        value: state.meals.isNotEmpty ? state.meals[0].value.asFixedTruncated(0) : "0",
        max: state.meals.isNotEmpty ? state.meals[0].max.asFixedTruncated(0) : "0",
        image: Assets.images.breakfast.image(),
        onTap: onBreakfastTap,
      ),
      MealInfo(
        title: Strings.lunch,
        value: state.meals.length > 1 ? state.meals[1].value.asFixedTruncated(0) : "0",
        max: state.meals.length > 1 ? state.meals[1].max.asFixedTruncated(0) : "0",
        image: Assets.images.lunch.image(),
        onTap: onLunchTap,
      ),

      MealInfo(
        title: Strings.snacks,
        value: state.meals.length > 2 ? state.meals[2].value.asFixedTruncated(0) : "0",
        max: state.meals.length > 2 ? state.meals[2].max.asFixedTruncated(0) : "0",
        image: Assets.images.snacks.image(),
        onTap: onSnackTap,
      ),
      MealInfo(
        title: Strings.dinner,
        value: state.meals.length > 3 ? state.meals[3].value.asFixedTruncated(0) : "0",
        max: state.meals.length > 3 ? state.meals[3].max.asFixedTruncated(0) : "0",
        image: Assets.images.dinner.image(),
        onTap: onDinnerTap,
      ),
    ];
  }
}
