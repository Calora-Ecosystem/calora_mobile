import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/presentation/dashboard/features/profile/features/norms_page/management/norms_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class NormsManager extends Manager<NormsState, NormsEffect> {
  final ProfileRepo _repo;
  NormsManager(this._repo) : super(const NormsState());

  void getDailyNorms() {
    _repo.getDailyNorms().then((value) {
      emit(state.copyWith(dailyNorms: value));
    });
  }

  void updateDailyNorms({
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? water,
    double? steps,
  }) {
    emit(
      state.copyWith(
        dailyNorms: state.dailyNorms.copyWith(
          calories: calories ?? state.dailyNorms.calories,
          protein: protein ?? state.dailyNorms.protein,
          fat: fat ?? state.dailyNorms.fat,
          carbs: carbs ?? state.dailyNorms.carbs,
          water: water ?? state.dailyNorms.water,
          steps: steps ?? state.dailyNorms.steps,
        ),
      ),
    );
  }
}
