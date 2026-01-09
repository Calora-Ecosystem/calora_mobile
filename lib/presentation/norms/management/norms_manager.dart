import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/norms/management/norms_management.dart';

@injectable
class NormsManager extends Manager<NormsState, NormsEffect> {
  final ProfileRepo _repo;

  NormsManager(this._repo) : super(const NormsState());

  void getDailyNorms() {
    _repo.getDailyNorms().handle(
      onStart: () => emit(state.copyWith(loading: true)),
      onData: (data) =>
          emit(state.copyWith(dailyNormsList: data, loading: false)),
      onDone: () => emit(state.copyWith(loading: false)),
    );
  }

  void updateDailyNorms(DetailInfo info, String lastResult) {
    final resultData = state.dailyNormsList.map((e) {
      if (e.type == info.type) {
        return e.copyWith(message: lastResult);
      }
      return e;
    }).toList();

    final metricName = _getMetricName(info.type);
    final request = NormsRequest(
      metric: metricName,
      value: double.parse(lastResult),
    );

    _repo
        .updateSingleNorm(request)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (data) =>
              emit(state.copyWith(dailyNormsList: resultData, loading: false)),
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }

  String _getMetricName(DetailInfoType type) {
    switch (type) {
      case DetailInfoType.dailyCalorieNorm:
        return 'Kcal';
      case DetailInfoType.dailyProteinNorm:
        return 'Protein';
      case DetailInfoType.dailyFatNorm:
        return 'Fat';
      case DetailInfoType.dailyCarbohydrateNorm:
        return 'Carb';
      case DetailInfoType.dailyWaterNorm:
        return 'Water';
      case DetailInfoType.dailyStepNorm:
        return 'Step';
      default:
        throw Exception('Noma\'lum norm turi: $type');
    }
  }
}
