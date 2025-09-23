import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/norms/daily_norms_info.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'norms_management.dart';

@injectable
class NormsManager extends Manager<NormsState, NormsEffect> {
  final ProfileRepo _repo;
  NormsManager(this._repo) : super(const NormsState());

  void getDailyNorms() {
    _repo.getDailyNorms().handle(
      onStart: () => emit(state.copyWith(loading: true)),
      onData: (data) => emit(state.copyWith(dailyNormsList: data, loading: false)),
      onDone: () => emit(state.copyWith(loading: false)),
    );
  }

  void updateDailyNorms(DetailInfo info, String lastResult) {
    var resultData = state.dailyNormsList.map((e) {
      if (e.type == info.type) {
        return e.copyWith(message: lastResult);
      }
      return e;
    }).toList();
    DailyNormsInfo dailyNormsInfo = DailyNormsInfo(
      calories: double.parse(resultData[0].message),
      protein: double.parse(resultData[1].message),
      carbs: double.parse(resultData[2].message),
      fat: double.parse(resultData[3].message),
      steps: double.parse(resultData[4].message),
      water: double.parse(resultData[5].message),
    );
    _repo
        .updateDailyNorms(dailyNormsInfo)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (data) => emit(state.copyWith(dailyNormsList: resultData, loading: false)),
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }
}
