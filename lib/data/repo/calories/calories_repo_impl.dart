import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/dish/dish_data.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CaloriesRepo)
class CaloriesRepoImpl implements CaloriesRepo {
  @override
  Future<List<MealData>> getMeals() {
    return Future.value(meals);
  }

  @override
  Future<DailyCalories> getCalories() {
    return Future.value(calories);
  }

  @override
  Future<List<DishData>> getDishes(MealCategory category) {
    return Future.value(dishes.where((element) => element.type == category).toList());
  }

  DailyCalories calories = DailyCalories(plan: 520, consumed: 410, leftover: 500);

  List<MealData> meals = [
    MealData(max: 540, value: 501, type: MealType.breakfast, mass: 250, carbohydrates: 100, proteins: 100, oils: 100),
    MealData(max: 1000, value: 482, type: MealType.lunch, mass: 300, carbohydrates: 50, proteins: 50, oils: 50),
    MealData(max: 300, value: 230, type: MealType.snacks, mass: 247, carbohydrates: 70, proteins: 70, oils: 70),
    MealData(max: 1000, value: 0, type: MealType.dinner, mass: 280, carbohydrates: 90, proteins: 90, oils: 90),
  ];

  List<DishData> dishes = [
    DishData(
      name: 'Mastava',
      imageUrl: 'assets/images/liquid_foods.png',
      type: MealCategory.liquid,
      oils: 100,
      proteins: 100,
      carbohydrates: 100,
      description:
          'Mastava — bu go‘sht, sabzavotlar, guruch va ayrim hollarda no‘xat bilan tayyorlanadigan mazali va to‘yimli sho‘rva. U iliq yoki issiq holda dasturxonga tortiladi va ayniqsa kechki ovqatga juda mos keladi. Shuningdek, ko‘pchilik tomonidan oshga o‘xshatiladi, lekin bu suyuq ko‘rinishda bo‘ladi. ',
    ),
    DishData(
      name: 'Uygurcha lagmon',
      imageUrl: 'assets/images/liquid_foods.png',
      type: MealCategory.drinks,
      oils: 100,
      proteins: 100,
      carbohydrates: 100,
      description:
          'Mastava — bu go‘sht, sabzavotlar, guruch va ayrim hollarda no‘xat bilan tayyorlanadigan mazali va to‘yimli sho‘rva. U iliq yoki issiq holda dasturxonga tortiladi va ayniqsa kechki ovqatga juda mos keladi. Shuningdek, ko‘pchilik tomonidan oshga o‘xshatiladi, lekin bu suyuq ko‘rinishda bo‘ladi. ',
    ),
    DishData(
      name: 'Chalop',
      imageUrl: 'assets/images/liquid_foods.png',
      type: MealCategory.breakfast,
      oils: 100,
      proteins: 100,
      carbohydrates: 100,
      description:
          'Mastava — bu go‘sht, sabzavotlar, guruch va ayrim hollarda no‘xat bilan tayyorlanadigan mazali va to‘yimli sho‘rva. U iliq yoki issiq holda dasturxonga tortiladi va ayniqsa kechki ovqatga juda mos keladi. Shuningdek, ko‘pchilik tomonidan oshga o‘xshatiladi, lekin bu suyuq ko‘rinishda bo‘ladi. ',
    ),
    DishData(
      name: 'Chalop',
      imageUrl: 'assets/images/liquid_foods.png',
      type: MealCategory.pureed,
      oils: 100,
      proteins: 100,
      carbohydrates: 100,
      description:
          'Mastava — bu go‘sht, sabzavotlar, guruch va ayrim hollarda no‘xat bilan tayyorlanadigan mazali va to‘yimli sho‘rva. U iliq yoki issiq holda dasturxonga tortiladi va ayniqsa kechki ovqatga juda mos keladi. Shuningdek, ko‘pchilik tomonidan oshga o‘xshatiladi, lekin bu suyuq ko‘rinishda bo‘ladi. ',
    ),
    DishData(
      name: 'Chalop',
      imageUrl: 'assets/images/liquid_foods.png',
      type: MealCategory.fastFood,
      oils: 100,
      proteins: 100,
      carbohydrates: 100,
      description:
          'Mastava — bu go‘sht, sabzavotlar, guruch va ayrim hollarda no‘xat bilan tayyorlanadigan mazali va to‘yimli sho‘rva. U iliq yoki issiq holda dasturxonga tortiladi va ayniqsa kechki ovqatga juda mos keladi. Shuningdek, ko‘pchilik tomonidan oshga o‘xshatiladi, lekin bu suyuq ko‘rinishda bo‘ladi. ',
    ),
    DishData(
      name: 'Chalop',
      imageUrl: 'assets/images/liquid_foods.png',
      type: MealCategory.fastFood,
      oils: 100,
      proteins: 100,
      carbohydrates: 100,
      description:
          'Mastava — bu go‘sht, sabzavotlar, guruch va ayrim hollarda no‘xat bilan tayyorlanadigan mazali va to‘yimli sho‘rva. U iliq yoki issiq holda dasturxonga tortiladi va ayniqsa kechki ovqatga juda mos keladi. Shuningdek, ko‘pchilik tomonidan oshga o‘xshatiladi, lekin bu suyuq ko‘rinishda bo‘ladi. ',
    ),
    DishData(
      name: 'Chalop',
      imageUrl: 'assets/images/liquid_foods.png',
      type: MealCategory.fastFood,
      oils: 100,
      proteins: 100,
      carbohydrates: 100,
      description:
          'Mastava — bu go‘sht, sabzavotlar, guruch va ayrim hollarda no‘xat bilan tayyorlanadigan mazali va to‘yimli sho‘rva. U iliq yoki issiq holda dasturxonga tortiladi va ayniqsa kechki ovqatga juda mos keladi. Shuningdek, ko‘pchilik tomonidan oshga o‘xshatiladi, lekin bu suyuq ko‘rinishda bo‘ladi. ',
    ),
  ];
}
