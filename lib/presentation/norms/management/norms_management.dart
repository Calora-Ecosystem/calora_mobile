import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'norms_management.freezed.dart';

@freezed
abstract class NormsState with _$NormsState {
  const factory NormsState({
    @Default(false) bool loading,
    @Default([]) List<DetailInfo> dailyNormsList,
  }) = _NormsState;
}

@freezed
class NormsEffect with _$NormsEffect {}
